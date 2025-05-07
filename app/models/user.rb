class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { admin: "admin", profissional: "profissional" }, _prefix: true

  def admin?
    role == "admin"
  end

  def profissional?
    role == "profissional"
  end
end
