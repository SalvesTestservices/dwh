module IconHelper
  def icon(name, width: 7, height: 7, classes: '')
    case name
    when :logout
      logout_icon(width: width, height: height, classes: classes)
    when :users
      users_icon(width: width, height: height, classes: classes)
    else
      raise ArgumentError, "Unknown icon: #{name}"
    end
  end

  private

  def logout_icon(width:, height:, classes:)
    <<-SVG.html_safe
      <svg xmlns="http://www.w3.org/2000/svg" 
           fill="none" 
           viewBox="0 0 24 24" 
           stroke-width="1.5" 
           stroke="currentColor" 
           class="w-#{width} h-#{height} #{classes}">
        <path stroke-linecap="round" 
              stroke-linejoin="round" 
              d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15M12 9l-3 3m0 0l3 3m-3-3h12.75" />
      </svg>
    SVG
  end

  def users_icon(width:, height:, classes:)
    <<-SVG.html_safe
      <svg xmlns="http://www.w3.org/2000/svg" 
           fill="none" 
           viewBox="0 0 24 24" 
           stroke-width="1.5" 
           stroke="currentColor" 
           class="w-#{width} h-#{height} #{classes}">
        <path stroke-linecap="round" 
              stroke-linejoin="round" 
              d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
      </svg>
    SVG
  end
end
