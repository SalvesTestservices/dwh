class View::IconComponent < ViewComponent::Base
  def initialize(icon_type:, size:, color:)
    @size = set_size(size)
    @color = set_color(color)
    @icon = set_icon(icon_type)
  end

  private def set_size(size)
    case size
    when "small"
      size = "20"
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
    when "users"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-users-group' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><path d='M10 13a2 2 0 1 0 4 0a2 2 0 0 0 -4 0' /><path d='M8 21v-1a2 2 0 0 1 2 -2h4a2 2 0 0 1 2 2v1' /><path d='M15 5a2 2 0 1 0 4 0a2 2 0 0 0 -4 0' /><path d='M17 10h2a2 2 0 0 1 2 2v1' /><path d='M5 5a2 2 0 1 0 4 0a2 2 0 0 0 -4 0' /><path d='M3 13v-1a2 2 0 0 1 2 -2h2' /></svg>"
    when "home"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-home-2' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><polyline points='5 12 3 12 12 3 21 12 19 12' /><path d='M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-7' /><rect x='10' y='12' width='4' height='4' /></svg>"
    when "notification"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-bell' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><path d='M10 5a2 2 0 0 1 4 0a7 7 0 0 1 4 6v3a4 4 0 0 0 2 3h-16a4 4 0 0 0 2 -3v-3a7 7 0 0 1 4 -6' /><path d='M9 17v1a3 3 0 0 0 6 0v-1' /></svg>"
    when "logout"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' width='#{@size}' height='#{@size}' stroke-width='2'> <path d='M14 8v-2a2 2 0 0 0 -2 -2h-7a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h7a2 2 0 0 0 2 -2v-2'></path> <path d='M9 12h12l-3 -3'></path> <path d='M18 15l3 -3'></path> </svg> "
    when "pipeline"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 14 14' id='Line-Arrow-Roadmap--Streamline-Flex-Remix' width='#{@size}' height='#{@size}'><g id='line-arrow-roadmap'><path id='Union' fill='#{@color}' fill-rule='evenodd' d='M3.875 2.5c0 -0.48325 0.39175 -0.875 0.875 -0.875s0.875 0.39175 0.875 0.875 -0.39175 0.875 -0.875 0.875 -0.875 -0.39175 -0.875 -0.875Zm-1.1566 -0.625H1.25c-0.345178 0 -0.625 0.27982 -0.625 0.625s0.279822 0.625 0.625 0.625h1.4684c0.26689 0.86858 1.07551 1.5 2.0316 1.5 0.95609 0 1.76471 -0.63142 2.0316 -1.5H10c0.8975 0 1.625 0.72754 1.625 1.625 0 0.63801 -0.368 1.19057 -0.9031 1.45641C10.4074 5.42591 9.64305 4.875 8.75 4.875c-0.95609 0 -1.76471 0.63142 -2.0316 1.5H3.5C1.91218 6.375 0.625 7.66218 0.625 9.25c0 1.3053 0.86948 2.4069 2.06111 2.758 0.22773 0.9283 1.06538 1.617 2.06389 1.617 0.95609 0 1.76471 -0.6314 2.0316 -1.5h4.8657c-0.2103 0.194 -0.3644 0.2363 -0.3973 0.2363 -0.3452 0 -0.625 0.2798 -0.625 0.625s0.2798 0.625 0.625 0.625c0.527 0 1.0065 -0.3257 1.3326 -0.6518 0.324 -0.324 0.6102 -0.7592 0.7486 -1.2291 0.0283 -0.0713 0.0438 -0.149 0.0438 -0.2304l0 -0.0069c0.0005 -0.0532 -0.0057 -0.1064 -0.0187 -0.1584 -0.1262 -0.5051 -0.4285 -0.9763 -0.7737 -1.3216 -0.3261 -0.32608 -0.8056 -0.65177 -1.3326 -0.65177 -0.3452 0 -0.625 0.27982 -0.625 0.625 0 0.34517 0.2798 0.62497 0.625 0.62497 0.0343 0 0.2012 0.0462 0.4263 0.2637H6.7816c-0.26689 -0.8686 -1.07551 -1.5 -2.0316 -1.5 -0.89305 0 -1.65744 0.55091 -1.97186 1.3314 -0.53515 -0.2658 -0.90314 -0.81839 -0.90314 -1.4564 0 -0.89746 0.72754 -1.625 1.625 -1.625h3.2184c0.26689 0.86858 1.07551 1.5 2.0316 1.5 0.99851 0 1.8362 -0.68868 2.0639 -1.61696C12.0055 7.15687 12.875 6.0553 12.875 4.75c0 -1.58782 -1.2872 -2.875 -2.875 -2.875H6.7816C6.51471 1.00642 5.70609 0.375 4.75 0.375c-0.95609 0 -1.76471 0.63142 -2.0316 1.5ZM3.875 11.5v-0.0026l0.00012 -0.0118c0.00769 -0.4766 0.39644 -0.8606 0.87488 -0.8606 0.48325 0 0.875 0.3918 0.875 0.875s-0.39175 0.875 -0.875 0.875 -0.875 -0.3918 -0.875 -0.875ZM8.75 6.125c0.47845 0 0.86721 0.38401 0.87488 0.86063l0.00012 0.01171V7c0 0.48325 -0.39175 0.875 -0.875 0.875S7.875 7.48325 7.875 7s0.39175 -0.875 0.875 -0.875Z' clip-rule='evenodd' stroke-width='1'></path></g></svg>"
    when "datalab"
      icon = "<svg id='Chemical-Lab--Streamline-Atlas' xmlns='http://www.w3.org/2000/svg' viewBox='-0.5 -0.5 16 16' width='#{@size}' height='#{@size}'><defs></defs><path d='m4.518750000000001 0.9375 5.9624999999999995 0' fill='none' stroke='#{@color}' stroke-miterlimit='10' stroke-width='1'></path><path d='M9.2875 3.9187499999999997V0.9375H5.7125v2.9812499999999997L1.6875 11.96875a1.4375 1.4375 0 0 0 -0.15625 0.625 1.45 1.45 0 0 0 1.45 1.46875h9.037500000000001a1.45 1.45 0 0 0 1.45 -1.45 1.4375 1.4375 0 0 0 -0.15625 -0.625Z' fill='none' stroke='#000000' stroke-miterlimit='10' stroke-width='1'></path><path d='M4.3062499999999995 6.725c3.125 -1.35625 3.3187499999999996 1.1875 6.5125 0.25625' fill='none' stroke='#000000' stroke-miterlimit='10' stroke-width='1'></path><path d='m4.518750000000001 11.675 1.1937499999999999 0' fill='none' stroke='#000000' stroke-miterlimit='10' stroke-width='1'></path><path d='m6.30625 9.2875 1.1937499999999999 0' fill='none' stroke='#000000' stroke-miterlimit='10' stroke-width='1'></path><path d='m9.2875 10.48125 1.1937499999999999 0' fill='none' stroke='#000000' stroke-miterlimit='10' stroke-width='1'></path></svg>"
    when "table"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' fill='#{@color}' class='bi bi-table' viewBox='0 0 16 16' id='Table--Streamline-Bootstrap' width='#{@size}' height='#{@size}'><desc>Table Streamline Icon: https://streamlinehq.com</desc><path d='M0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2H2a2 2 0 0 1 -2 -2zm15 2h-4v3h4zm0 4h-4v3h4zm0 4h-4v3h3a1 1 0 0 0 1 -1zm-5 3v-3H6v3zm-5 0v-3H1v2a1 1 0 0 0 1 1zm-4 -4h4V8H1zm0 -4h4V4H1zm5 -3v3h4V4zm4 4H6v3h4z' stroke-width='1'></path></svg>"
    when "history"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-history' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><path d='M12 8l0 4l2 2' /><path d='M3.05 11a9 9 0 1 1 .5 4m-.5 5v-5h5' /></svg>"
    when "check"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' width='#{@size}' height='#{@size}' stroke-width='2'> <path d='M3.5 5.5l1.5 1.5l2.5 -2.5'></path> <path d='M3.5 11.5l1.5 1.5l2.5 -2.5'></path> <path d='M3.5 17.5l1.5 1.5l2.5 -2.5'></path> <path d='M11 6l9 0'></path> <path d='M11 12l9 0'></path> <path d='M11 18l9 0'></path> </svg>"
    when "pause"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-player-pause' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><path d='M6 5m0 1a1 1 0 0 1 1 -1h2a1 1 0 0 1 1 1v12a1 1 0 0 1 -1 1h-2a1 1 0 0 1 -1 -1z' /><path d='M14 5m0 1a1 1 0 0 1 1 -1h2a1 1 0 0 1 1 1v12a1 1 0 0 1 -1 1h-2a1 1 0 0 1 -1 -1z' /></svg>"
    when "start"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-player-play' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><path d='M7 4v16l13 -8z' /></svg>"
    when "timer"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' width='#{@size}' height='#{@size}' stroke-width='2'> <path d='M5 13a7 7 0 1 0 14 0a7 7 0 0 0 -14 0z'></path> <path d='M14.5 10.5l-2.5 2.5'></path> <path d='M17 8l1 -1'></path> <path d='M14 3h-4'></path> </svg>"
    when "target"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' width='#{@size}' height='#{@size}' stroke-width='2'> <path d='M12 12m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0'></path> <path d='M12 7a5 5 0 1 0 5 5'></path> <path d='M13 3.055a9 9 0 1 0 7.941 7.945'></path> <path d='M15 6v3h3l3 -3h-3v-3z'></path> <path d='M15 9l-3 3'></path> </svg>"
    when "download"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='-0.5 -0.5 16 16' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' class='feather feather-download' id='Download--Streamline-Feather' width='#{@size}' height='#{@size}'><path d='M13.125 9.375v2.5a1.25 1.25 0 0 1 -1.25 1.25H3.125a1.25 1.25 0 0 1 -1.25 -1.25v-2.5' stroke-width='1'></path><path d='m4.375 6.25 3.125 3.125 3.125 -3.125' stroke-width='1'></path><path d='m7.5 9.375 0 -7.5' stroke-width='1'></path></svg>"
    when "bonus"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-gift' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><rect x='3' y='8' width='18' height='4' rx='1' /><line x1='12' y1='8' x2='12' y2='21' /><path d='M19 12v7a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2v-7' /><path d='M7.5 8a2.5 2.5 0 0 1 0 -5a4.8 8 0 0 1 4.5 5a4.8 8 0 0 1 4.5 -5a2.5 2.5 0 0 1 0 5' /></svg>"    
    when "holiday"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' width='#{@size}' height='#{@size}' stroke-width='2'> <path d='M7 18a2 2 0 1 0 4 0a2 2 0 0 0 -4 0'></path> <path d='M11 18h7a2 2 0 0 0 2 -2v-7a2 2 0 0 0 -2 -2h-9.5a5.5 5.5 0 0 0 -5.5 5.5v3.5a2 2 0 0 0 2 2h2'></path> <path d='M8 7l7 -3l1 3'></path> <path d='M13 11m0 .5a.5 .5 0 0 1 .5 -.5h2a.5 .5 0 0 1 .5 .5v2a.5 .5 0 0 1 -.5 .5h-2a.5 .5 0 0 1 -.5 -.5z'></path> <path d='M20 16h2'></path> </svg>"
    when "filter"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' width='#{@size}' height='#{@size}' stroke-width='2'> <path d='M4 4h16v2.172a2 2 0 0 1 -.586 1.414l-4.414 4.414v7l-6 2v-8.5l-4.48 -4.928a2 2 0 0 1 -.52 -1.345v-2.227z'></path> </svg>"
    when "filter-x"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' width='#{@size}' height='#{@size}' stroke-width='2'> <path d='M13.758 19.414l-4.758 1.586v-8.5l-4.48 -4.928a2 2 0 0 1 -.52 -1.345v-2.227h16v2.172a2 2 0 0 1 -.586 1.414l-4.414 4.414v1.5'></path> <path d='M22 22l-5 -5'></path> <path d='M17 22l5 -5'></path> </svg>"
    when "certificate"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-file-certificate' width='#{@size}' height='#{@size}' viewBox='0 0 24 24' stroke-width='1.5' stroke='#{@color}' fill='none' stroke-linecap='round' stroke-linejoin='round'><path stroke='none' d='M0 0h24v24H0z' fill='none'/><path d='M14 3v4a1 1 0 0 0 1 1h4' /><path d='M5 8v-3a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2h-5' /><circle cx='6' cy='14' r='3' /><path d='M4.5 17l-1.5 5l3 -1.5l3 1.5l-1.5 -5' /></svg>"
    when "security"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' width='#{@size}' height='#{@size}' stroke-width='2'> <path d='M5 13a2 2 0 0 1 2 -2h10a2 2 0 0 1 2 2v6a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2v-6z'></path> <path d='M11 16a1 1 0 1 0 2 0a1 1 0 0 0 -2 0'></path> <path d='M8 11v-4a4 4 0 1 1 8 0v4'></path> </svg>"
    when "catalog"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 48 48' width='#{@size}' height='#{@size}'><path stroke='#{@color}' stroke-linejoin='round' d='M37.44 5.52H10.5601C7.83 5.52 6.045 6.99 5.52 9.72L2.16 25.68v11.76c0.0039 1.3355 0.5361 2.6152 1.4805 3.5595 0.9443 0.9444 2.224 1.4766 3.5595 1.4805h33.6c1.3355 -0.0039 2.6152 -0.5361 3.5595 -1.4805 0.9444 -0.9443 1.4766 -2.224 1.4805 -3.5595V25.68L42.48 9.72c-0.5251 -2.835 -2.415 -4.2 -5.04 -4.2Z' stroke-width='3'></path><path stroke='#000000' stroke-linecap='round' stroke-linejoin='round' d='M2.16 25.6799h15.12' stroke-width='3'></path><path stroke='#000000' stroke-linecap='round' stroke-linejoin='round' d='M30.7197 25.6799h15.12' stroke-width='3'></path><path stroke='#000000' stroke-linecap='round' stroke-linejoin='round' d='M17.2797 25.6799c0 1.7823 0.7081 3.4915 1.9682 4.7518 1.2602 1.2603 2.9695 1.9682 4.7518 1.9682s3.4915 -0.7079 4.7518 -1.9682c1.2602 -1.2603 1.9682 -2.9695 1.9682 -4.7518' stroke-width='3'></path><path stroke='#000000' stroke-linecap='round' stroke-linejoin='round' d='M12.2399 12.2403H35.76' stroke-width='3'></path><path stroke='#000000' stroke-linecap='round' stroke-linejoin='round' d='M10.5599 18.9603H37.44' stroke-width='3'></path></svg>"
    when "log"
      icon = "<svg viewBox='0 0 16 16' width='#{@size}' height='#{@size}'><path d='M13 1H4a1 1 0 0 0 -1 1v2H2v1h1v2.5H2v1h1v2.5H2v1h1v2a1 1 0 0 0 1 1h9a1 1 0 0 0 1 -1V2a1 1 0 0 0 -1 -1Zm0 13H4v-2h1v-1H4v-2.5h1v-1H4v-2.5h1V4H4V2h9Z' fill='#000000' stroke-width='0.5'></path><path d='M7 4h4v1h-4Z' fill='#000000' stroke-width='0.5'></path><path d='M7 7.5h4v1h-4Z' fill='#000000' stroke-width='0.5'></path><path d='M7 11h4v1h-4Z' fill='#{@color}' stroke-width='0.5'></path><path id='_Transparent_Rectangle_' d='M0 0h16v16H0Z' fill='none' stroke-width='0.5'></path></svg>"
    when "api"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' width='#{@size}' height='#{@size}' stroke-width='2'> <path d='M10 19a2 2 0 1 0 -4 0a2 2 0 0 0 4 0z'></path> <path d='M18 5a2 2 0 1 0 -4 0a2 2 0 0 0 4 0z'></path> <path d='M10 5a2 2 0 1 0 -4 0a2 2 0 0 0 4 0z'></path> <path d='M6 12a2 2 0 1 0 -4 0a2 2 0 0 0 4 0z'></path> <path d='M18 19a2 2 0 1 0 -4 0a2 2 0 0 0 4 0z'></path> <path d='M14 12a2 2 0 1 0 -4 0a2 2 0 0 0 4 0z'></path> <path d='M22 12a2 2 0 1 0 -4 0a2 2 0 0 0 4 0z'></path> <path d='M6 12h4'></path> <path d='M14 12h4'></path> <path d='M15 7l-2 3'></path> <path d='M9 7l2 3'></path> <path d='M11 14l-2 3'></path> <path d='M13 14l2 3'></path> </svg>"
    when "lock"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' width='#{@size}' height='#{@size}' stroke-width='2'> <path d='M5 13a2 2 0 0 1 2 -2h10a2 2 0 0 1 2 2v6a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2v-6z'></path> <path d='M11 16a1 1 0 1 0 2 0a1 1 0 0 0 -2 0'></path> <path d='M8 11v-4a4 4 0 1 1 8 0v4'></path> </svg>"
    when "exit"
      icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='#{@color}' stroke-linecap='round' stroke-linejoin='round' width='#{@size}' height='#{@size}' stroke-width='2'> <path d='M14 8v-2a2 2 0 0 0 -2 -2h-7a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h7a2 2 0 0 0 2 -2v-2'></path> <path d='M9 12h12l-3 -3'></path> <path d='M18 15l3 -3'></path> </svg>"
    end
    icon.html_safe
  end
end