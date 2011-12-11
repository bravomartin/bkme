


class Response
  attr_accessor :source, :user
 
  def initialize(user, source)
    @user = user
    @source = source
  end
end