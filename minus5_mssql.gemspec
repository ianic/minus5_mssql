require 'rake'

GEMSPEC = Gem::Specification.new do |spec|

  spec.name = 'minus5_mssql'
  spec.summary = "minus5 mssql library"
  spec.version = File.read('VERSION').strip
  spec.author = 'Igor Anic'
  spec.email = 'ianic@minus5.hr'

  spec.add_dependency('tiny_tds', '~> 0.5.0')

  spec.files = FileList['lib/*', 'lib/**/*', 'tasks/*' , 'bin/*', 'test/*','test/**/*', 'Rakefile'].to_a

  spec.homepage = 'http://www.minus5.hr'
  spec.test_files = FileList['test/*_test.rb'].to_a

  spec.description = <<-EOF
  minus5_mssql is a simple lib for working with Microsoft Sql Server
  it is built on top of tiny_tds (https://github.com/rails-sqlserver/tiny_tds)
  EOF
end
