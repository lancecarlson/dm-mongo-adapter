require 'rubygems'

gem 'dm-core', '~> 0.10.2'
gem 'mongo', '~> 0.16'

require 'dm-core'
require 'mongo'

dir = Pathname(__FILE__).dirname.expand_path / 'mongo_adapter'

require dir / 'query'
require dir / 'conditions'
require dir / 'types' / 'object_id'
require dir / 'types' / 'db_ref'
require dir / 'types' / 'objects'
require dir / 'resource'

require dir / 'embedments' / 'relationship'
require dir / 'embedments' / 'one_to_one'
require dir / 'embedments' / 'one_to_many'

require dir / 'model' / 'embedment'
require dir / 'embedded_model'
require dir / 'embedded_resource'
require dir / 'adapter'
