require "rails_helper"

describe DeploymentRun, type: :model do
  it "has a valid factory" do
    expect(create(:deployment_run)).to be_valid
  end

  describe "#start_upload!" do
    let(:step) { create(:releases_step, :with_deployment) }
    let(:step_run) { create(:releases_step_run, :deployment_started, step: step) }

    it "marks as completed if deployment is external" do
      external_deployment = create(:deployment, step: step, integration: nil)
      deployment_run = create(:deployment_run, :started, deployment: external_deployment, step_run: step_run)

      deployment_run.start_upload!
      expect(deployment_run.reload.released?).to be(true)
    end

    it "marks as uploaded if there is another similar deployment which has uploaded" do
      integration = create(:integration)
      deployment1 = create(:deployment, step: step, integration: integration)
      deployment2 = create(:deployment, step: step, integration: integration)
      _deployment_run1 = create(:deployment_run, :uploaded, deployment: deployment1, step_run: step_run)
      deployment_run2 = create(:deployment_run, :started, deployment: deployment2, step_run: step_run)

      deployment_run2.start_upload!
      expect(deployment_run2.reload.uploaded?).to be(true)
    end

    it "does nothing if there is another similar deployment which has started upload" do
      integration = create(:integration)
      deployment1 = create(:deployment, step: step, integration: integration)
      deployment2 = create(:deployment, step: step, integration: integration)
      _deployment_run1 = create(:deployment_run, :started, deployment: deployment1, step_run: step_run)
      deployment_run2 = create(:deployment_run, :started, deployment: deployment2, step_run: step_run)

      deployment_run2.start_upload!
      expect(deployment_run2.reload.started?).to be(true)
    end

    it "starts upload if it is the only deployment with google play store" do
      integration = create(:integration, :with_google_play_store)
      deployment1 = create(:deployment, step: step, integration: integration)
      deployment_run1 = create(:deployment_run, :started, deployment: deployment1, step_run: step_run)
      allow(Deployments::GooglePlayStore::Upload).to receive(:perform_later)

      deployment_run1.start_upload!

      expect(Deployments::GooglePlayStore::Upload).to have_received(:perform_later).with(deployment_run1.id).once
      expect(deployment_run1.reload.started?).to be(true)
    end

    it "starts upload if it is the only deployment with slack" do
      integration = create(:integration, :with_slack)
      deployment1 = create(:deployment, step: step, integration: integration)
      deployment_run1 = create(:deployment_run, :started, deployment: deployment1, step_run: step_run)
      allow(Deployments::Slack).to receive(:perform_later)

      deployment_run1.start_upload!
      expect(Deployments::Slack).to have_received(:perform_later).with(deployment_run1.id).once
      expect(deployment_run1.reload.started?).to be(true)
    end

    it "starts upload if a different deployment has happened before" do
      integration1 = create(:integration)
      deployment1 = create(:deployment, step: step, integration: integration1)
      _deployment_run1 = create(:deployment_run, :released, deployment: deployment1, step_run: step_run)

      integration2 = create(:integration, :with_google_play_store)
      deployment2 = create(:deployment, step: step, integration: integration2)
      deployment_run2 = create(:deployment_run, :started, deployment: deployment2, step_run: step_run)

      allow(Deployments::GooglePlayStore::Upload).to receive(:perform_later)

      deployment_run2.start_upload!
      expect(Deployments::GooglePlayStore::Upload).to have_received(:perform_later).with(deployment_run2.id).once
      expect(deployment_run2.reload.started?).to be(true)
    end
  end
end