class Subject < ActiveRecord::Base
  belongs_to :space
  belongs_to :owner, :class_name => "User", :foreign_key => :user_id
  has_many :lectures, :order => "position", :dependent => :destroy
  has_many :enrollments, :dependent => :destroy
  has_many :members, :through => :enrollments, :source => :user,
    :dependent => :destroy
  has_many :graduated_members, :through => :enrollments, :source => :user,
    :include => :student_profiles,
    :conditions => ["student_profiles.graduaded = 1"]
  has_many :teachers, :through => :enrollments, :source => :user,
    :conditions => ["enrollments.role_id = ?", Role[:teacher].id]
  has_many :statuses, :as => :statusable, :dependent => :destroy

  attr_protected :owner, :published

  acts_as_taggable

  validates_presence_of :title
  validates_size_of :description, :within => 30..200
  validates_length_of :lectures, :minimum => 1, :on => :update

  # Matricula o usuário com o role especificado. Retorna true ou false
  # dependendo do resultado
  def enroll(user, role = Role[:member])
    enrollment = self.enrollments.create(:user => user, :role_id => role.id)
    enrollment.valid?
  end

  # Desmatricula o usuário e retorna o mesmo
  def unenroll(user)
    self.members.delete(user)
  end

  def publish!
   self.published = true
   self.save
  end

  def unpublish!
    self.enrollments.destroy_all
    self.published = false
    self.save
  end

  def change_lectures_order!(lectures_ordered)
    ids_ordered = []
    lectures_ordered.each do |lecture|
      ids_ordered << lecture.split("-")[0].to_i
    end

    ids_ordered.each_with_index do |id, i|
      lecture = Lecture.find(id)
      lecture.position = i + 1 # Para não ficar índice zero.
      lecture.save
    end
  end

  #TODO colocar esse metodo em status passando apenas o objeto
  # Não foi testado, pois haverá reformulação de subject
  def recent_activity(page = 1)
    self.statuses.paginate(:all, :page => page, :order => 'created_at DESC',
                           :per_page => AppConfig.items_per_page)
  end

end
