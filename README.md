# AvtiveOopish

[![Gem Version](https://badge.fury.io/rb/activeoopish.svg)](http://badge.fury.io/rb/activeoopish) [![Build Status](https://travis-ci.org/yuku-t/activeoopish.svg?branch=master)](https://travis-ci.org/yuku-t/activeoopish) [![Code Climate](https://codeclimate.com/github/yuku-t/activeoopish/badges/gpa.svg)](https://codeclimate.com/github/yuku-t/activeoopish) [![Coverage Status](https://coveralls.io/repos/yuku-t/activeoopish/badge.svg)](https://coveralls.io/r/yuku-t/activeoopish) [![Dependency Status](https://gemnasium.com/yuku-t/activeoopish.svg)](https://gemnasium.com/yuku-t/activeoopish)

Simple tools for better OOP in Rails projects.

## ActiveOopish::Validator

Encapsulates the responsibility of validating a model into a validator.

```rb
class BookValidator < ActiveOopish::Validator
  declear do
    validates :author, presence: true

    validates :title, length: { minimum: 3, maximum: 255 }

    validate :title_must_include_author_name, if: :biography?
  end

  def title_must_include_author_name(book)
    unless book.title.include?(book.author.name)
      book.errors.add(:author, "cannot write a biography for other people")
    end
  end

  def biography?(book)
    book.category == :biography
  end
end

class Book < ActiveRecord::Base
  belongs_to :author, class_name: 'User'

  BookValidator.monitor(self)
end
```

### RSpec

```rb
require 'activeoopish/rspec_helper'
require 'shoulda-matchers'

describe Book do
  it { should be_monitored_by BookValidator }
end

describe BookValidator, :with_activeoopish_helper do
  include_context 'describe declaration' do
    it { should validate_presence_of(:author) }

    it { should validate_length_of(:title).is_at_least(3).is_at_most(255) }

    context 'when #biography? returns true' do
      before do
        allow_any_instance_of(described_class)
          .to receive(:biography?).and_return(true)
      end

      it 'calls #title_must_include_author_name' do
        expect_any_instance_of(described_class)
          .to receive(:title_must_include_author_name).with(subject).once
        subject.valid?
      end
    end
  end

  describe '#biography?' do
    # ...
  end

  describe '#title_must_include_author_name' do
    # ...
  end
end
```
