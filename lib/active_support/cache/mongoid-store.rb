# encoding: utf-8
#
require 'mongoid'
require 'active_support'

module ActiveSupport
  module Cache
    class MongoidStore < Store
      attr_reader :collection_name

      def initialize(options = {})
        @collection_name = options[:collection] || :rails_cache
        options[:expires_in] ||= 1.hour
        super(options)
      end

      def clear(options = nil)
        collection.find.remove_all
      end

      def cleanup(options = nil)
        options = merged_options(options)
        collection.find(expires_at: {'$lt' => Time.now.utc.to_i}).remove_all
      end

      def delete_matched(matcher, options = nil)
        options = merged_options(options)
        collection.find(_id: key_matcher(matcher, options)).remove_all
      end

      def delete_entry(key, options = nil)
        collection.find(_id: key).remove
      end

    protected

      def write_entry(key, entry, options)
        data = Entry.data_for(entry)
        expires_at = entry.expires_at.to_i
        created_at = Time.now.utc.to_i

        collection.find(_id: key).upsert(_id: key, data: data, expires_at: expires_at, created_at: created_at)

        entry
      end

      def read_entry(key, options = {})
        expires_at = Time.now.utc.to_i
        doc = collection.find(_id: key, expires_at: {'$gt' => expires_at}).first

        Entry.for(doc) if doc
      end

    # this class exists to normalize between rails3 and rails4, but also to
    # repair totally broken interfaces in rails - especially in rails3 - that
    # result in lots of extra serialization/deserialzation in a class which is
    # supposed to be FAST
    #
      class Entry < ::ActiveSupport::Cache::Entry
        def Entry.is_rails3?
          unless defined?(@is_rails3)
            @is_rails3 = new(nil).instance_variable_defined?('@value')
          end

          @is_rails3
        end

      # extract marshaled data from a cache entry without doing unnecessary
      # marshal round trips.  rails3 will have either a nil or pre-marshaled
      # @value whereas rails4 will have either a marshaled or un-marshaled @v.
      # in both cases we want to avoid calling the silly 'value' accessor
      # since this will cause a potential Marshal.load call and require us to
      # make a subsequent Marshal.dump call which is SLOOOWWW.
      #
        if is_rails3?

          def Entry.data_for(entry)
            value = entry.instance_variable_get('@value')
            marshaled = value.nil? ? Marshal.dump(value) : value
            ::BSON::Binary.new(:generic, marshaled)
          end

        else

          def Entry.data_for(entry)
            v = entry.instance_variable_get('@v')
            marshaled = entry.send('compressed?') ? v : entry.send('compress', v)
            ::BSON::Binary.new(:generic, marshaled)
          end

        end

      # the intializer for rails' default Entry class will go ahead and
      # perform and extraneous Marshal.dump on the data we just got from the
      # db even though we don't need it here.  rails3 has a factory to avoid
      # this but rails4 does not so we just build the object we want and
      # ensure to avoid any unnecessary calls to Marshal.dump/load...  sigh.
      #
        if is_rails3?

          def Entry.for(doc)
            data = doc['data'].to_s
            value = Marshal.load(data)
            created_at = doc['created_at'].to_f

            allocate.tap do |entry|
              entry.instance_variable_set(:@value, value)
              entry.instance_variable_set(:@compressed, false)
              entry.instance_variable_set(:@created_at, created_at)
            end
          end

        else

          def Entry.for(doc)
            data = doc['data'].to_s
            value = Marshal.load(data)
            created_at = doc['created_at'].to_f

            allocate.tap do |entry|
              entry.instance_variable_set(:@v, value)
              entry.instance_variable_set(:@c, false)
            end
          end

        end

        def value
          Entry.is_rails3? ? @value : @v
        end

        def raw_value
          Entry.is_rails3? ? @value : @v
        end
      end

    private

      def collection
        Mongoid.session(:default)[collection_name]
      end
    end
  end
end
