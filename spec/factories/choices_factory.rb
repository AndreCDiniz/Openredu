# -*- encoding : utf-8 -*-
# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :choice do
    association :user
  end
end
