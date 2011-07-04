require 'rubygems'
require 'test/unit'
require 'pp'

$LOAD_PATH.unshift File.dirname(__FILE__) + "/../lib"
require 'minus5_mssql.rb'

module Helper 

  protected

  def setup_table(adapter)
    adapter.execute "
    if not exists(select * from sys.objects where name = 'people')
    create table people (id int identity, first_name varchar(255), last_name varchar(255))
    "
    adapter.execute "truncate table people"
    adapter.execute "insert into people (first_name, last_name) values ('Sasa', 'Juric')"
    adapter.execute "insert into people (first_name, last_name) values ('Goran', 'Pizent')"
 end

  def rollback_transaction(client)
    client.execute("BEGIN TRANSACTION").do
    yield
  ensure
    client.execute("ROLLBACK TRANSACTION").do
  end

end
