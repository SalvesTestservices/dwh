module ApplicationHelper
  def decorate(object, klass = nil)
    unless object.nil?
      klass ||= "#{object.class}Decorator".constantize
      decorator = klass.new(object, self)
      yield decorator if block_given?
      decorator
    end
  end
end