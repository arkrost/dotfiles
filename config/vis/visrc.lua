require('vis')

vis.events.start = function() 
	vis:command('set theme dark-16')
	vis:command('set tabwidth 2')
	vis:command('set autoindent')
	
	vis:command('map! normal j gj')
	vis:command('map! normal k gk')
end

vis.events.win_open = function(win)
	vis.filetype_detect(win)
end
