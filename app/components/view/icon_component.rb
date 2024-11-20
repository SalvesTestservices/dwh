class View::IconComponent < ViewComponent::Base
  def initialize(icon_type:, size:, color:)
    @size = set_size(size)
    @color = set_color(color)
    @icon = set_icon(icon_type)
  end

  private def set_size(size)
    case size
    when "small"
      size = "24"
    when "medium"
      size = "32"
    when "large"
      size = "64"
    end
  end

  private def set_color(color)
    case color
    when "white"
      color = "#FFFFFF"
    when "gray"
      color = "#374151"
    when "red"
      color = "#dc2626"
    when "green"
      color = "#16a34a"
    end
  end

  private def set_icon(icon_type)
    case icon_type
    when "create"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-square-plus' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><rect x='4' y='4' width='16' height='16' rx='2' /><line x1='9' y1='12' x2='15' y2='12' /><line x1='12' y1='9' x2='12' y2='15' /></svg>"
    when "edit"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-pencil' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><path d='M4 20h4l10.5 -10.5a1.5 1.5 0 0 0 -4 -4l-10.5 10.5v4' /><line x1='13.5' y1='6.5' x2='17.5' y2='10.5' /></svg>"
    when "delete"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-trash' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><line x1='4' y1='7' x2='20' y2='7' /><line x1='10' y1='11' x2='10' y2='17' /><line x1='14' y1='11' x2='14' y2='17' /><path d='M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12' /><path d='M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3' /></svg>"
    when "save"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-check' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='2.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><path d='M5 12l5 5l10 -10' /></svg>"
    when "cancel"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-x' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><line x1='18' y1='6' x2='6' y2='18' /><line x1='6' y1='6' x2='18' y2='18' /></svg>"
    when "settings"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-settings' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><path d='M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065z' /><circle cx='12' cy='12' r='3' /></svg>"
    when "user-group"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-users-group' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><path d='M10 13a2 2 0 1 0 4 0a2 2 0 0 0 -4 0' /><path d='M8 21v-1a2 2 0 0 1 2 -2h4a2 2 0 0 1 2 2v1' /><path d='M15 5a2 2 0 1 0 4 0a2 2 0 0 0 -4 0' /><path d='M17 10h2a2 2 0 0 1 2 2v1' /><path d='M5 5a2 2 0 1 0 4 0a2 2 0 0 0 -4 0' /><path d='M3 13v-1a2 2 0 0 1 2 -2h2' /></svg>"
    when "home"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-home-2' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><polyline points='5 12 3 12 12 3 21 12 19 12' /><path d='M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-7' /><rect x='10' y='12' width='4' height='4' /></svg>"
    when "notification"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-bell' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><path d='M10 5a2 2 0 0 1 4 0a7 7 0 0 1 4 6v3a4 4 0 0 0 2 3h-16a4 4 0 0 0 2 -3v-3a7 7 0 0 1 4 -6' /><path d='M9 17v1a3 3 0 0 0 6 0v-1' /></svg>"
    when "logout"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' width='#{@size}' height='#{@size}' stroke-width='2'> <path d='M14 8v-2a2 2 0 0 0 -2 -2h-7a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h7a2 2 0 0 0 2 -2v-2'></path> <path d='M9 12h12l-3 -3'></path> <path d='M18 15l3 -3'></path> </svg> "
    when "pipeline"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' width='#{@size}' height='#{@size}' stroke-width='2'> <path d='M3 19a2 2 0 1 0 4 0a2 2 0 0 0 -4 0'></path> <path d='M19 7a2 2 0 1 0 0 -4a2 2 0 0 0 0 4z'></path> <path d='M11 19h5.5a3.5 3.5 0 0 0 0 -7h-8a3.5 3.5 0 0 1 0 -7h4.5'></path> </svg>"
    end
    icon.html_safe
  end
end