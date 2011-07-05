$LOAD_PATH.unshift File.dirname(__FILE__)
require 'helper.rb'

class Select < Test::Unit::TestCase
  include Helper

  def setup
    @reader = Minus5::Mssql::Adapter.new({:username => "rails",
                                         :password => "",
                                         :host => "mssql",
                                         :database => "minus5_mssql_tests"}) 
    create_tables
  end

  def test_select_value
    assert_equal 1, @reader.select_value("select 1")
    assert_equal 1, @reader.select_value("select 1, 2")
    assert_equal 1, @reader.select_value("select 1\nunion\nselect 2")
    assert_equal 1, @reader.select_value("select 1; select 2")
    assert_nil @reader.select_value("set nocount on")
  end

  def test_select_values
    assert_equal [1,2], @reader.select_values("select 1, 11\nunion\nselect 2, 22")
    assert_equal [1,2], @reader.select_values("select 1, 11\nunion\nselect 2, 22; select 3, 3")
    assert_equal [], @reader.select_values("set nocount on")
  end
  
  def test_select_simple
    assert_equal([{:first => 1, :second => 2}], @reader.select("select 1 first, 2 second"))
    assert_equal([{:first => 1, :second => 2}], @reader.select(:sql=>"select 1 first, 2 second"))
    assert_equal [], @reader.select("set nocount on")
  end

  def test_get_params
    columns = @reader.send(:get_params, 'people')
    assert_equal 3, columns.size
    assert columns.include?("id")
    assert columns.include?("first_name")
    assert columns.include?("last_name")
  end

  def test_insert_delete
    id = @reader.insert('people', {:first_name => "Igor", :last_name => "Anic"})
    assert_equal 3, @reader.select_value("select count(*) from people")
    @reader.delete('people', {:id => id})
    assert_equal 2, @reader.select_value("select count(*) from people")
  end


  def test_simple_select
    result = @reader.select("select * from orders")
    assert result.kind_of?(Array)
    assert_equal 3, result.size
    assert_equal 3, result[0].keys.size
  end

  def test_parent_child_one_to_many_and_one_to_one
    result = @reader.select(
        :sql=>"select * from orders; select * from order_details order by no; select order_id, sum(no) sum_no from order_details group by order_id",
        :primary_key=>:id,
        :relations=>[{:type=>:one_to_many, :name=>:order_details, :foreign_key=>:order_id},
                     {:type=>:one_to_one, :foreign_key=>:order_id}]
    )
    assert result.kind_of?(Array)
    assert_equal 3, result.size
    assert_equal 5, result[0].keys.size
    3.times do |i|
      parent = result[i]
      childs = parent[:order_details]
      assert childs.kind_of?(Array)
      assert_equal 5, childs.size
      childs.each_with_index do |child, j|
        assert_equal i+1, child[:order_id]
        assert_equal j, child[:no]
      end
      assert_not_nil parent[:sum_no] 
    end
    #pp result
  end

  def test_one_to_one
    result = @reader.select(
        :sql=>"select * from orders; select order_id, sum(no) sum_no from order_details group by order_id",
        :primary_key=>:id,
        :relations=>[{:type=>:one_to_one, :name=>:sum, :foreign_key=>:order_id}]
    )
    #pp result
    assert_equal 4, result[0].keys.size
    assert result[0][:sum].kind_of?(Hash)
  end

  private 

  def create_tables
    @reader.create_table "dbo", "people", 
      "id int identity, first_name varchar(255), last_name varchar(255)"
    @reader.execute "truncate table dbo.people"
    @reader.insert "dbo.people", {:first_name=>"Sasa", :last_name=>"Juric"}
    @reader.insert "dbo.people", {:first_name=>"Goran", :last_name=>"Pizent"}

    @reader.create_table "dbo", "orders",
      "id int identity, created datetime, amount money"
    @reader.create_table "dbo", "order_details",
      "id int identity, order_id int, no int" 
    @reader.execute "truncate table dbo.orders"
    @reader.execute "truncate table dbo.order_details"
    3.times do |o|
      id = @reader.insert "orders", {:created=>Time.now, :amount=>1234.5 * (o + 1)}
      5.times{|no| @reader.insert "order_details", {:order_id=>id, :no=>no}}
    end
    @reader.execute "drop procedure all_orders"
    @reader.execute <<-SQL
      create procedure all_orders as
        select * from orders
        select order_id parent_id, * from order_details
    SQL
  end

end
