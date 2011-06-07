module MongoidExt
  module Voteable
    extend ActiveSupport::Concern

    included do
      field :votes_count, :type => Integer, :default => 0
      field :votes_average, :type => Integer, :default => 0

      field :votes, :type => Hash, :default => {}
    end

    def vote!(value, voter_id, &block)
      old_vote = self.votes[voter_id]
      if old_vote.nil?
        self.votes[voter_id] = value
        self.save
        add_vote!(value, voter_id, &block)
        return :created
      else
        if(old_vote != value)
          self.votes[voter_id] = value
          self.save
          self.remove_vote!(old_vote, voter_id, &block)
          self.add_vote!(value, voter_id, &block)

          return :updated
        else
          self.votes.delete(voter_id)
          self.save
          remove_vote!(value, voter_id, &block)
          return :destroyed
        end
      end
    end

    def add_vote!(value, voter_id, &block)
      if embedded?
        self._parent.increment({self._position+".votes_count" => 1,
                                self._position+".votes_average" => value.to_i})
      else
        self.increment({:votes_count => 1, :votes_average => value.to_i})
      end

      block.call(value, :add) if block

      self.on_add_vote(value, voter_id) if self.respond_to?(:on_add_vote)
    end

    def remove_vote!(value, voter_id, &block)
      if embedded?
        self._parent.increment({self._position+".votes_count" => -1,
                                self._position+".votes_average" => -value.to_i})
      else
        self.increment({:votes_count => -1, :votes_average => -value})
      end

      block.call(value, :remove) if block

      self.on_remove_vote(value, voter_id) if self.respond_to?(:on_remove_vote)
    end

    module ClassMethods
    end
  end
end