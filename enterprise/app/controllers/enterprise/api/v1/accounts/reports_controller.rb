module Enterprise::Api::V1::Accounts::ReportsController
  include Concerns::SubscriptionCheck

  private

  def required_subscription_feature
    'reports' # Requires Professional tier
  end
end
