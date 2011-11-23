require 'spec_helper'
require 'authlogic/test_case'

describe ChoicesController do
  include Authlogic::TestCase
  before do
    User.maintain_sessions = false
    @space = Factory(:space)
    activate_authlogic

    @subject = Factory(:subject, :owner => @space.owner,
                       :space => @space, :finalized => true,
                       :visible => true)
    @exercise = Factory(:complete_exercise)
    @questions = @exercise.questions
    @lecture = Factory(:lecture,:subject => @subject, :lectureable => @exercise,
                       :owner => @space.owner)

    @user = Factory(:user)
    @space.course.join(@user)
    UserSession.create @user
  end

  context "POST create" do
    before do
      @exercise.start_for(@user)
      @alternative = @questions.first.alternatives.first
      @question = @questions.first
      @params = { :locale => 'pt-BR', :format => :html }
      @params.merge!(:exercise_id => @exercise.id,
                     :question_id => @question.id,
                     :choice => { :alternative_id => @alternative.id })
    end

    it "should load the exercise" do
      post :create, @params
      assigns[:exercise].should_not be_nil
    end

    it "should load the question" do
      post :create, @params
      assigns[:question].should_not be_nil
    end

    it "should create the choice" do
      expect {
        post :create, @params
      }.should change(Choice, :count).by(1)
    end

    it "should not double the choice" do
      post :create, @params

      expect {
        post :create, @params
      }.should_not change(Choice, :count)
    end

    it "should redirect to the next question" do
      post :create, @params
      @next = @question.next_item
      response.should redirect_to(exercise_question_path(@exercise, @next))
    end

    context "when last question" do
      before do
        @last = @questions.last
        @params.merge!({:question_id => @last.id,
                        :choice => { :alternative_id => @last.alternatives.first}})
      end

      it "should redirect to results edit" do
        result = @exercise.start_for(@user)
        post :create, @params
        response.should redirect_to edit_exercise_result_path(@exercise, result)
      end
    end

    context "when there is no answer" do
      before do
        @params.delete(:choice)
      end

      it "should not raise error" do
        expect {
          post :create, @params
        }.should_not raise_error
      end

      it "should redirect to the next question" do
        post :create, @params
        @next = @questions[1]
        response.should redirect_to(exercise_question_path(@exercise, @next))
      end
    end

    context "when submiting via 'Anterior' button" do
      before do
        @params.merge!(:commit => 'Anterior')
        @params.merge!(:question_id => @questions[1])
        @params.merge!(:choice => { :alternative_id =>
                                    @questions[1].alternatives.first })
      end

      it "should redirect to the previous question" do
        post :create, @params
        @first = @questions[0]
        response.should redirect_to(exercise_question_path(@exercise, @first))
      end
    end
  end
end