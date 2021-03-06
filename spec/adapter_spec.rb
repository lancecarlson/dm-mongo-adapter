require File.join(File.dirname(__FILE__), 'spec_helper')
require File.join(File.dirname(__FILE__), 'adapter_shared_spec')

describe DataMapper::Adapters::MongoAdapter do
  before :all do

    # let's start with an empty collection
    $db.drop_collection('heffalumps')

    # DataMapper::Logger.new(STDOUT, :debug)
    cleanup_models :Heffalump

    class ::Heffalump
      include DataMapper::Mongo::Resource

      property :id,        ObjectID
      property :color,     String
      property :num_spots, Integer
      property :striped,   Boolean
    end
  end

  it_should_behave_like "An Adapter"

  describe "queries" do
    before :all do
      @red   = Heffalump.create(:color => 'red', :num_spots => 2)
      @green = Heffalump.create(:color => 'green', :num_spots => 3)
      @blue  = Heffalump.create(:color => 'blue', :num_spots => 5)
    end

    it "should be able to search for objects matching conditions for the same property" do
      col = Heffalump.all(:num_spots.gt => 2, :num_spots.not => 3)

      col.size.should == 1
      col.first.should eql(@blue)
    end
  end

  describe "embedded objects as properties" do
    before :all do
      cleanup_models :Zoo

      class Zoo
        include DataMapper::Mongo::Resource

        property :id, ObjectID
        property :animals, EmbeddedArray
        property :address, EmbeddedHash
      end
    end

    describe "using arrays" do
      it "should save a resource" do
        zoo = Zoo.new
        zoo.animals = [:marty, :alex, :gloria]

        lambda {
          zoo.save
        }.should_not raise_error
      end

      it "should be able to search with 'equal to' criterium" do
        penguins = [:skipper, :kowalski, :private, :rico]
        Zoo.create(:animals => penguins)

        zoo = Zoo.first(:animals => penguins)
        zoo.should_not be_nil
        zoo.animals.should eql(penguins)
      end
    end

    describe "using hashes" do
      it "should save a resource" do
        zoo = Zoo.new
        zoo.address = {:street => 'Street 1', :telephone => '123-45-67'}

        lambda {
          zoo.save
          zoo.address.class.should be(Hash)
        }.should_not raise_error
      end

      it "should set the property value as hash" do
        _id = $db.collection('zoos').insert(:address => { :street => 'Street 2' })

        zoo = Zoo.get(_id)

        zoo.address.should be_kind_of(Hash)
        zoo.address[:street].should eql('Street 2')
      end

      it "should be able to search with 'equal to' criterium" do
        address = {:street => 'Street 3'}

        Zoo.create(:address => address)

        zoo = Zoo.first(:address => address)

        zoo.should_not be_nil
        zoo.address.should eql(address)
      end
    end
  end

  describe "associations" do
    before :all do
      cleanup_models :User, :Group

      class User
        include DataMapper::Mongo::Resource

        property :id, ObjectID
        property :group_id, DBRef
        property :name, String
        property :age, Integer
      end

      class Group
        include DataMapper::Mongo::Resource

        property :id, ObjectID
        property :name, String
      end

      User.belongs_to :group
      Group.has Group.n, :users
    end

    before :each do
      $db.drop_collection('users')
      $db.drop_collection('groups')

      @john = User.create(:name => 'john', :age => 101)
      @jane = User.create(:name => 'jane', :age => 102)

      @group = Group.create(:name => 'dm hackers')
    end

    describe "belongs_to" do
      it "should set parent object _id in the db ref" do
        lambda {
          @john.group = @group
          @john.save
        }.should_not raise_error

        @john.group_id.should eql(@group.id)
      end

      it "should fetch parent object" do
        user = User.create(:name => 'jane')
        user.group_id = @group.id
        user.group.should eql(@group)
      end

      it "should work with SEL" do
        users = User.all(:name => /john|jane/)

        users.each { |u| u.update(:group_id => @group.id) }

        users.each do |user|
          user.group.should_not be_nil
        end
      end
    end

    describe "has many" do
      before :each do
        [@john, @jane].each { |user| user.update(:group_id => @group.id) }
      end

      it "should get children" do
        @group.users.size.should eql(2)
      end

      it "should add new children with <<" do
        user = User.new(:name => 'kyle')
        @group.users << user
        user.group_id.should eql(@group.id)
        @group.users.size.should eql(3)
      end

      it "should replace children" do
        user = User.create(:name => 'stan')
        @group.users = [user]
        @group.users.size.should eql(1)
        @group.users.first.should eql(user)
      end

      it "should fetch children matching conditions" do
        users = @group.users.all(:name => 'john')
        users.size.should eql(1)
      end
    end
  end
end
