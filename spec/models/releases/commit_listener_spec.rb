require "rails_helper"

describe Releases::CommitListener do
  it "has valid factory" do
    expect(create(:releases_commit_listener)).to be_valid
  end
end
