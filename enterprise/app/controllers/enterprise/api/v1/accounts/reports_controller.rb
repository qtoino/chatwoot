module Enterprise::Api::V1::Accounts::ReportsController
  private

  def required_subscription_feature
    'reports' # Requires Professional tier
  end
end
