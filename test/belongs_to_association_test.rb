# frozen_string_literal: true

require "test_helper"

class BelongsToAssociationTest < ActiveSupport::TestCase
  def setup
    @user = User.create name: "csdn", email: "test@csdn.com"
  end

  def test_should_get_cache_when_use_belongs_to_association
    book = @user.books.create

    @user.write_second_level_cache

    assert_no_queries do
      assert_equal @user, book.user
    end
  end

  def test_should_write_belongs_to_association_cache
    book = @user.books.create
    @user.expire_second_level_cache
    assert_nil User.read_second_level_cache(@user.id)
    assert_equal @user, book.user
    # assert_not_nil User.read_second_level_cache(@user.id)
  end

  # Owner with query_constraints makes active_record_primary_key return the owner's
  # query_constraints_list, which must not disable caching of the target lookup.
  def test_should_get_cache_when_owner_has_query_constraints
    skip "query_constraints requires Rails 7.1+" unless ::ActiveRecord::Base.respond_to?(:query_constraints)

    ActiveRecord::Base.connection.create_table(:events, force: true) do |t|
      t.integer :user_id
      t.datetime :created_at
    end
    event_class = Class.new(ApplicationRecord) do
      self.table_name = "events"
      query_constraints :id, :created_at
      belongs_to :user
      def self.name
        "Event"
      end
    end

    event = event_class.create!(user_id: @user.id)
    event = event_class.find_by(id: event.id)
    @user.write_second_level_cache

    assert_no_queries do
      assert_equal @user, event.user
    end
  end
end
