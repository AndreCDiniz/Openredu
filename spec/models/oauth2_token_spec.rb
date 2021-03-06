# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AccessToken do
  it "should return token from user" do
    user = FactoryBot.create(:user)
    application = FactoryBot.create(:client_application, :user => user)
    access = AccessToken.create(:user => user,
                                :client_application => application)
    token = access.token

    AccessToken.user_token_for(user, application).token.should \
      == token
  end
end
