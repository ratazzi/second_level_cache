# frozen_string_literal: true

module SecondLevelCache
  module ActiveRecord
    module Associations
      module BelongsToAssociation
        def find_target(*args, **kwargs)
          return super if kwargs[:async]
          return super unless klass.second_level_cache_enabled?
          return super if klass.default_scopes.present? || reflection.scope
          return super if reflection.association_primary_key(klass).to_s != klass.primary_key

          cache_record = klass.read_second_level_cache(second_level_cache_key)
          if cache_record
            return cache_record.tap { |record| set_inverse_instance(record) }
          end

          record = super
          return nil unless record

          record.tap do |r|
            set_inverse_instance(r)
            r.write_second_level_cache
          end
        end

        private
          # Rails 7.1+ derives a composite foreign_key when the owner has query_constraints,
          # and pairs it with the (single) primary key by position, so use the first column.
          def second_level_cache_key
            owner[Array(reflection.foreign_key).first]
          end
      end
    end
  end
end
