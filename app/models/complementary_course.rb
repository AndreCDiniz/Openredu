class ComplementaryCourse < ActiveRecord::Base
  # Representa uma formação do usuário em um Curso Complementar
  # É uma especialização de Education

  validates_presence_of :course, :institution, :year, :workload
end