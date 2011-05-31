module Minus5

  module Mssql

    class Adapter

      # params - tiny_tds connection params: https://github.com/rails-sqlserver/tiny_tds
      # with additon of mirror_host
      # Example:
      #    SqlBase.new({  :username    => "rails",
      #                   :password    => "",
      #                   :host        => "bedem",
      #                   :mirror_host => "mssql",
      #                   :database    => "activerecord_unittest_mirroring"
      #                })
      def initialize(params)
        params = YAML.load_file(params).symbolize_keys if params.kind_of?(String)
        @params = params
        @params_cache = {}
        connect
      end

      # Insert row into table_name.
      # Data is hash {column_name => value, ...}
      # Acutal column names will be discovered from database.
      def insert(table_name, data)
        columns = get_params(table_name).reject{|c| c == "id"}
        values = hash_to_values columns, data
        sql = "insert into #{table_name} (#{columns.join(',')}) values (#{values.join(',')})"
        execute(sql).insert
      end

      # Delete rows from table_name.
      # Data is hash with keys eg. {:id => 123}
      def delete(table_name, data)
        columns, values = hash_to_columns_values(data)
        keys = []
        for i in (0..columns.size-1)
          keys << "#{columns[i]} = #{values[i]}"
        end
        sql = "delete from #{table_name} where #{keys.join(' and ')}"
        execute(sql).cancel
      end

      # Send query to the database. With reconnect in case of db mirroring failover.
      def execute(sql)
        @connection.execute(sql)
      rescue TinyTds::Error => e
        print "execute error #{e}\n"
        connect
        execute(sql)
      end

      # Returns results first column of the first row.
      def select_value(sql)
        rows = execute(sql).each
        return nil if rows.size == 0
        row = rows[0]
        row[row.keys[0]]
      end

      def select(sql)
        rows = execute(sql).each
        rows.size == 1 ? rows[0] : rows
      end

      private

      def connect
        print "connecting to #{@params[:host]} "
        @connection = TinyTds::Client.new(@params)
        print "successful\n"
      rescue TinyTds::Error => e
        print "#{e.to_s}\n"
        throw unless @params[:mirror_host]
        to_mirror
        connect
      end

      # Switch host and mirror_host in @params
      def to_mirror
        host = @params[:host]
        @params[:host] = @params[:mirror_host]
        @params[:mirror_host] = host
        @params[:dataserver] = "#{@params[:host]}:#{@params[:port] || 1433}"
      end

      # Read table or stored procedure param names from database.
      # Returns array of table column names or stored procedure param
      def get_params(name)
        @params_cache[name] ||=
        begin
          sql = "select name from sys.syscolumns where id = object_id('#{name}')"
          @connection.execute(sql).each.map{|row| row["name"]}
        end
      end

      def hash_to_values(columns, data)
        values = columns.map do |column|
          value = data[column.to_sym]
          value = data[column.to_s]  if value.nil?
          if column == "time" && value.kind_of?(String)
            value = Time.parse(value)
          end
          if value.nil?
            'null'
          elsif value.kind_of?(String)
            #"'#{value.gsub("\'","''")}'"
            "'#{@connection.escape(value)}'"
          elsif value.kind_of?(Date)
            "'#{value.strftime("%Y-%m-%d")}'"
          elsif value.kind_of?(Time) || value.kind_of?(DateTime)
            "'#{value.strftime("%Y-%m-%d %H:%M:%S")}'"
          elsif value.kind_of?(Integer) || value.kind_of?(Fixnum) || value.kind_of?(Bignum) || value.kind_of?(Float) || value.kind_of?(Rational)
            "#{value.to_s}"
          else
            "'#{@connection.escape(value.to_s)}'"
          end
        end
        values
      end

      def hash_to_columns_values(data)
        columns = data.each_key.map{|key| key.to_s}
        [columns, hash_to_values(columns, data)]
      end

    end

  end

end