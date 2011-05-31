require 'rubygems'
require 'test/unit'
require 'pp'

$LOAD_PATH.unshift File.dirname(__FILE__) + "/../lib"
require 'minus5_mssql.rb'

class Reader < Minus5::Mssql::Adapter

  def read
    execute("select * from people").each(:symbolize_keys => true)
  end

  def failover
    execute("use master; ALTER DATABASE activerecord_unittest_mirroring SET PARTNER FAILOVER")
  end

end

class DbMirroring < Test::Unit::TestCase

  def setup
    @reader = Reader.new({:username => "rails",
                           :password => "",
                           :host => "bedem",
                           :mirror_host => "mssql",
                           :database => "activerecord_unittest_mirroring"})
  end

  def test_get_params
    columns = @reader.send(:get_params, 'people')
    assert_equal 3, columns.size
    assert columns.include?("id")
    assert columns.include?("first_name")
    assert columns.include?("last_name")
  end

  def test_insert
    rollback_transaction(@reader) do
      id = @reader.insert('people', {:first_name => "Igor", :last_name => "Anic"})
      assert_equal 3, @reader.select_value("select count(*) from people")
      @reader.delete('people', {:id => id})
      assert_equal 2, @reader.select_value("select count(*) from people")
    end
  end

  def test_read
    rows = @reader.read
    data_test rows
    pp rows
    @reader.failover
    rows = @reader.read
    data_test rows
  end

  def data_test(rows)
    assert_equal 2, rows.size
    assert "Sasa", rows[0][:first_name]
    assert "Goran", rows[1][:first_name]
  end

  private

  def setup_table
    @reader.execute "
    if not exists(select * from sys.objects where name = 'people')
    create table people (id int identity, first_name varchar(255), last_name varchar(255))
    "

    @reader.execute "truncate table people"
    @reader.execute "insert into people (first_name, last_name) values ('Sasa', 'Juric')"
    @reader.execute "insert into people (first_name, last_name) values ('Goran', 'Pizent')"
  end

  def rollback_transaction(client)
    client.execute("BEGIN TRANSACTION").do
    yield
  ensure
    client.execute("ROLLBACK TRANSACTION").do
  end


end
