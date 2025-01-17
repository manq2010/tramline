FactoryBot.define do
  factory :releases_commit_listener, class: "Releases::CommitListener" do
    association :train, factory: :releases_train
    branch_name { "feat/new_story" }
  end
end
