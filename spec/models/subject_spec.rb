require 'spec_helper'

describe Subject do
  before do
    environment = Factory(:environment)
    course = Factory(:course, :owner => environment.owner,
                     :environment => environment)
    @space = Factory(:space, :owner => environment.owner,
                    :course => course)
    @user = Factory(:user)
    course.join(@user)
  end


  subject { Factory(:subject, :owner => @user, :space => @space) }

  it { should belong_to :space }
  it { should belong_to :owner }
  it { should have_many(:lectures).dependent(:destroy) }
  it { should have_many(:enrollments).dependent(:destroy) }
  it { should have_many(:graduated_members).through :enrollments }
  it { should have_many(:members).through(:enrollments) }
  it { should have_many(:statuses).dependent(:destroy) }
  it { should have_many(:logs).dependent(:destroy) }

  it { should validate_presence_of :title }
  #FIXME falhando por problema de tradução
  xit { should ensure_length_of(:description).is_at_least(30).is_at_most(250) }

  it { should_not allow_mass_assignment_of(:owner) }
  it { should_not allow_mass_assignment_of(:visible) }
  it { should_not allow_mass_assignment_of(:finalized) }

  it "responds to tags" do
    should respond_to :tag_list
  end

  context "validations" do
    it "validates that it has at least one lecture on update" do
      subject = Factory(:subject, :owner => @user, :space => @space)
      subject.lectures = []
      subject.save
      subject.should_not be_valid
      subject.errors.on(:lectures).should_not be_nil
    end
  end

  context "callbacks" do

    it "creates an Enrollment between the Subject and the owner after create" do
      subject.create_enrollment_associations
      subject.enrollments.first.should_not be_nil
      subject.enrollments.last.user.should == subject.owner
      subject.enrollments.last.role.
        should == subject.owner.get_association_with(subject.space).role
      subject.enrollments.count.should == 2
    end

    it "does NOT create an Enrollment between the Subject and the owner when update it" do
      expect {
        subject.save # Other updates
      }.should_not change(subject.enrollments.reload, :count)
    end

    it "does NOT create an Enrollment between the subject and the owner after create, if the owner is a Redu admin" do
      redu_admin = Factory(:user, :role => Role[:admin])
      expect {
        Factory(:subject, :owner => redu_admin, :space => @space)
      }.should_not change(Enrollment, :count)
    end

  end

  context "finders" do
    it "retrieves visibles subjects" do
      subjects = (1..3).collect { Factory(:subject, :owner => @user,
                                          :space => @space) }
      visible_subjects = (1..3).collect { Factory(:subject, :owner => @user,
                                                    :space => @space,
                                                    :visible => true) }
      Subject.visible.should == visible_subjects
    end

    it "retrieves recent subjects (updated until 1 week ago)" do
      subjects = (1..3).collect { |i| Factory(:subject, :owner => @user,
                                              :space => @space,
                                              :updated_at => (i*3).day.ago) }
      Subject.recent.should == subjects[0..1]
    end

    it "retrieves graduated members" do
      users = (1..4).collect { Factory(:user) }
      users.each { |u| subject.enroll(u) }
      users[0..1].each do |u|
        student_profile = u.student_profiles.last
        student_profile.graduaded = 1
        student_profile.save
      end

      subject.graduated_members.should == users[0..1]
    end

    it "retrieves teachers" do
      users = (1..4).collect { Factory(:user) }
      teachers = (1..4).collect { Factory(:user) }
      users.each { |u| subject.enroll(u) }
      teachers.each { |u| subject.enroll(u, Role[:teacher]) }

      subject.teachers.should == teachers
    end
  end

  it "responds to recent?" do
    should respond_to :recent?
  end

  it "defaults to not visible" do
    subject { Factory(:subject, :visible => nil) }
    subject.visible.should be_false
  end

  it "responds to turn_visible!" do
    should respond_to :turn_visible!
  end

  it "responds to turn_invisible!" do
    should respond_to :turn_invisible!
  end

  it "indicates if it is recent (updated until 1 week ago)" do
    subject.should be_recent

    subject.updated_at = 10.day.ago
    subject.save
    subject.should_not be_recent
  end

  it "visibles itself" do
    subject = Factory(:subject, :owner => @user,
                      :space => @space, :visible => false)
    subject.turn_visible!
    subject.should be_visible
  end

  it "invisibles itself and removes all enrollments" do
    users = (1..4).collect { Factory(:user) }
    subject = Factory(:subject, :owner => @user,
                      :space => @space, :visible => true)
    users.each { |u| subject.enroll(u) }

    subject.turn_invisible!
    subject.should_not be_visible
  end

  it "responds to enroll" do
    should respond_to :enroll
  end

  it "responds to unenroll" do
    should respond_to :unenroll
  end

  context "enrollments" do
    before :each do
      @enrolled_user = Factory(:user)
    end

    it "enrolls an user" do
      expect {
        subject.enroll(@enrolled_user)
      }.should change(subject.enrollments, :count).by(1)
    end

    it "enrolls an user with a given role" do
      subject.enroll(@enrolled_user, Role[:teacher]).should be_true
      subject.enrollments.last.role.should == Role[:teacher]
    end

    it "unenrolls an user" do
      enrollment = Factory(:enrollment, :user => @enrolled_user,
                           :subject => subject)

      expect {
        subject.unenroll(@enrolled_user)
      }.should change(subject.enrollments, :count).by(-1)
    end
  end

  context "lectures" do
    it "changes lectures order" do
      lectures = (1..4).collect { Factory(:lecture, :subject => subject)}
      lectures_ordered = ["#{lectures[1].id}-lecture", "#{lectures[0].id}-lecture",
        "#{lectures[3].id}-lecture", "#{lectures[2].id}-lecture"]
      subject.change_lectures_order!(lectures_ordered)
      subject.reload.lectures.should == [lectures[1], lectures[0],
                                    lectures[3], lectures[2]]
    end
  end

end
