# frozen_string_literal: true

class SimpleSerializer
  class_attribute :_attributes
  self._attributes = {}
  class_attribute :_association
  self._association = {}
  class_attribute :_iso_timestamps
  self._iso_timestamps = []

  def initialize(object)
    @object = object
  end

  class << self
    # defined methods to store the attributes of the base serializer.
    # we are using these attributes to get the value from object.
    def attributes(*attrs)
      _attributes[to_s].present? ? _attributes[to_s] : _attributes[to_s] = []
      attrs.each do |attr|
        _attributes[to_s] << attr
      end
    end

    # create different methods for the different association to store these
    # we are using this to create the final json result hash.
    def belongs_to(*attrs)
      set_association_resource
      _association[to_s] = Base::Association::BelongsTo.new(attrs).set_hash(_association[to_s])
    end

    def has_one(*attrs) # rubocop:disable Naming/PredicateName
      set_association_resource
      _association[to_s] = Base::Association::HasOne.new(attrs).set_hash(_association[to_s])
    end

    def has_many(*attrs) # rubocop:disable Naming/PredicateName
      set_association_resource
      _association[to_s] = Base::Association::HasMany.new(attrs).set_hash(_association[to_s])
    end

    def set_association_resource
      _association[to_s] = {} unless _association[to_s].present?
    end

    # storing the columns to convert the value into iso_timestamp
    # converting the value in as_json method.
    def iso_timestamp_columns(options)
      options.each do |option|
        _iso_timestamps << option
      end
    end
  end

  # we are getting the final hash by this method. 
  def as_json # rubocop:disable Metrics/AbcSize
    result_hash = _attributes[self.class.to_s].map do |key|
      if _iso_timestamps.include?(key) # DOC: 
        [key, @object.send(key).presence.iso8601 || send(key).iso8601]
      else
        [key, @object.send(key).presence || send(key)]
      end
    end.to_h.with_indifferent_access
    result_hash.merge!(Base::Association::Config.new.get_hash(_association[self.class.to_s], @object))
  end
end
