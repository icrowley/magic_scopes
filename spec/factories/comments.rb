FactoryGirl.define do
  factory :comment do
    title { forgery(:lorem_ipsum).word }
    content { forgery(:lorem_ipsum).words(10) }

    association :user
    association :parent, factory: :comment
    commentable factory: :user
  end
end
