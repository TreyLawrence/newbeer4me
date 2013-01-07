$(document).ready(function() {
	$('a.untappd').live("click", function(){
		$(this).replaceWith(busyBar);
		window.location = "http://untappd.com/oauth/authenticate/" +
					"?client_id=9D467E2DB6750B919F95D156BA2099E32EF909E3" +
					"&client_secret=2EE43793B625BA1BD4E19E2111DF4E5C99045CAD" +
					"&response_type=code" +
					"&redirect_url=https://newbeer4me.herokuapp.com/untappd";
	});
});
