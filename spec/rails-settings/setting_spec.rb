require "spec_helper"

describe RailsSettings do
  before(:all) do
    @string      = 'string'
    @new_string  = 'new string'
    @hash        = { name: 'rails-settings' }
    @other_hash  = { address: 'Beijing.China' }
    @merged_hash = @hash.merge(@other_hash)
    @array       = ['first', 'last']
    @new_array   = ['first', 'middle', 'last']
    @user = User.create(name: 'rails-settings')
    @model_prefix = "#{@user.class.name.downcase}:#{@user.id}"
  end

  describe "For global settings" do
    before do
      Setting.string = @string
      Setting.hashes = @hash
      Setting.array  = @array
    end

    describe "Get" do
      describe "the multi-kinds of data" do
        it { Setting.string.should       == @string }
        it { Setting.hashes.should       == @hash }
        it { Setting.hashes.class.should == @hash.class }
        it { Setting.array.should        == @array }
        it { Setting.array.class.should  == @array.class }

        context 'also read the data from cache' do
          it { Rails.cache.fetch("settings:string").should == @string }
          it { Rails.cache.fetch("settings:hashes").should == @hash }
          it { Rails.cache.fetch("settings:array").should  == @array }
        end
      end
    end

    describe "Set" do
      before do
        Setting.string = @new_string
        Setting.array  = @new_array
        Setting.merge!(:hashes, @other_hash)
      end
      describe "with new data" do
        it { Setting.string.should       == @new_string }
        it { Setting.hashes.should       == @merged_hash }
        it { Setting.array.should        == @new_array }

        context 'also write the new data to cache at the same time' do
          it { Rails.cache.fetch("settings:string").should == @new_string }
          it { Rails.cache.fetch("settings:hashes").should == @merged_hash }
          it { Rails.cache.fetch("settings:array").should  == @new_array }
        end
      end
    end

    describe "Clear" do
      before do
        Setting.destroy(:string)
        Setting.destroy(:array)
        Setting.destroy(:hashes)
      end
      describe "the data" do
        it { Setting.string.should == nil }
        it { Setting.hashes.should == nil }
        it { Setting.array.should  == nil }

        context 'also with cache at the same time' do
          it { Rails.cache.fetch("settings:string").should == nil }
          it { Rails.cache.fetch("settings:hashes").should == nil }
          it { Rails.cache.fetch("settings:array").should  == nil }
        end
      end
    end

    describe "Use namespace for the keys" do
      before do
        Setting['namespace.firstname'] = 'first name'
        Setting['namespace.lastname']  = 'last name'
      end

      it { Setting['namespace.firstname'].should == 'first name' }
      it { Setting['namespace.lastname'].should  == 'last name' }

      context 'read the data from cache' do
        it { Rails.cache.fetch("settings:namespace.firstname").should == 'first name' }
        it { Rails.cache.fetch("settings:namespace.lastname").should  == 'last name' }
      end

      context "get the entries by namespace" do
        it { Setting.all.count.should == 5 }
        it { Setting.all('namespace').count.should == 2 }
      end
    end

  end

  describe "For embedded Model" do
    before do
      @user.settings.string = @string
      @user.settings.hashes = @hash
      @user.settings.array  = @array
    end

    describe "Get" do
      describe "the multi-kinds of data" do
        it { @user.settings.string.should       == @string }
        it { @user.settings.hashes.should       == @hash }
        it { @user.settings.hashes.class.should == @hash.class }
        it { @user.settings.array.should        == @array }
        it { @user.settings.array.class.should  == @array.class }

        context 'also read the data from cache' do
          it { Rails.cache.fetch("settings:#{@model_prefix}:string").should == @string }
          it { Rails.cache.fetch("settings:#{@model_prefix}:hashes").should == @hash }
          it { Rails.cache.fetch("settings:#{@model_prefix}:array").should  == @array }
        end
      end
    end

    describe "Set" do
      before do
        @user.settings.string = @new_string
        @user.settings.array  = @new_array
        @user.settings.merge!(:hashes, @other_hash)
      end
      describe "with new data" do
        it { @user.settings.string.should == @new_string }
        it { @user.settings.hashes.should == @merged_hash }
        it { @user.settings.array.should  == @new_array }

        context 'also write the new data to cache at the same time' do
          it { Rails.cache.fetch("settings:#{@model_prefix}:string").should == @new_string }
          it { Rails.cache.fetch("settings:#{@model_prefix}:hashes").should == @merged_hash }
          it { Rails.cache.fetch("settings:#{@model_prefix}:array").should  == @new_array }
        end
      end
    end

    describe "Clear" do
      before do
        @user.settings.destroy(:string)
        @user.settings.destroy(:array)
        @user.settings.destroy(:hashes)
      end
      describe "the data" do
        it { @user.settings.string.should == nil }
        it { @user.settings.hashes.should == nil }
        it { @user.settings.array.should  == nil }

        context 'also with cache at the same time' do
          it { Rails.cache.fetch("settings:#{@model_prefix}:string").should == nil }
          it { Rails.cache.fetch("settings:#{@model_prefix}:hashes").should == nil }
          it { Rails.cache.fetch("settings:#{@model_prefix}:array").should  == nil }
        end
      end
    end

    describe "Use namespace for the keys" do
      before do
        @user.settings['namespace.firstname'] = 'first name'
        @user.settings['namespace.lastname']  = 'last name'
      end

      it { @user.settings['namespace.firstname'].should == 'first name' }
      it { @user.settings['namespace.lastname'].should  == 'last name' }

      context 'read the data from cache' do
        it { Rails.cache.fetch("settings:#{@model_prefix}:namespace.firstname").should == 'first name' }
        it { Rails.cache.fetch("settings:#{@model_prefix}:namespace.lastname").should  == 'last name' }
      end

      context "get the entries by namespace" do
        it { @user.settings.all.count.should == 5 }
        it { @user.settings.all('namespace').count.should == 2 }
      end
    end
  end

end
