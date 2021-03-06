require 'spec_helper'

module StatusService
  module AnswerService
    describe AnswerNotificationService do
      let(:status) { FactoryBot.create(:activity) }
      let(:answer) do
        FactoryBot.create(:answer, in_response_to: status, statusable: status)
      end

      subject { AnswerNotificationService.new(answer) }

      context "#deliver" do
        it "should invoke StatusMailer" do
          StatusMailer.should_receive(:new_answer).
            with(an_instance_of(AnswerNotification)).once.and_call_original

          subject.deliver
        end

        it "should not send duplicated notification" do
          user = FactoryBot.create(:user)
          FactoryBot.create_list(:answer, 2, in_response_to: status,
                                  statusable: status, user: user)

          StatusMailer.should_receive(:new_answer).
            with(an_instance_of(AnswerNotification)).twice.and_call_original

          subject.deliver
        end
      end
    end
  end
end
