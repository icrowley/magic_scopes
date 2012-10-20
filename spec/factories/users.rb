FactoryGirl.define do
  factory :user do
    first_name { Forgery(:name).first_name }
    last_name  { Forgery(:name).last_name }
    email      { Forgery(:internet).email_address }
    gender     { %w(m f).sample }
  end
end
