(function() {
var ENTER = 13;
var search_count = {'beer' : 0, 'venue' : 0}
var collapsible_left = '<div data-role="collapsible" data-content-theme="c"><h3>';
var collapsible_right = "<img alt='Busy' src='/assets/busy.gif' align='right' ></h3><p>...</p></div>";
var search_type = 'beer';
$(document).ready(function() {
	$("#search").keypress(function(event) {
		if ( event.which == ENTER ) {
			event.preventDefault();
			var text = $('#search').val().trim();
			if ( text ) {
				search_count[search_type] += 1;
				$('#search').val('');
				$(collapsible_left + text + collapsible_right).addClass(search_type+search_count[search_type]).prependTo('[data-role="collapsible-set"].'+search_type+'s');
				$('[data-role="collapsible-set"].'+search_type+'s').collapsibleset('refresh');
				$.ajaxSetup({
					beforeSend: function(xhr) {
						xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
					}
				});
				$.ajax({
					type: "POST",
					url: "/search",
					data: {search: text, id: search_count[search_type], type: search_type}
				}).done(function( msg ) {
					var obj = jQuery.parseJSON(msg);
					$('[data-role="collapsible"].'+obj.type+obj.id).replaceWith(obj.result);
					$('[data-role="collapsible-set"].'+obj.type+'s').collapsibleset('refresh');
					if(obj.type == "venue") {
						$('[data-role="collapsible-set"].venue'+obj.id+'_beers').trigger('create').collapsibleset().collapsibleset('refresh');
					}
				});
			}
		}
	});
});

$(document).ready(function() {
	$('select').change(function() {
		if ($(this).val() == "on")
		{
			window.location.href = "https://foursquare.com/oauth2/authenticate" +
									"?client_id=DLTI5SNFPYNXCV4AKZYYPZWXOFWLS3B2ZBGOWEC1DB1NO3BJ" +
									"&response_type=code" +
									"&redirect_uri=https://newbeer4me.herokuapp.com/settings";
		} else {
			$.ajaxSetup({
				beforeSend: function(xhr) {
					xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
				}
			});
			$.ajax({
				type: "POST",
				url: "/disable",
			});
		}
	});
});

$(function() {
    $("a").click(function(){
        var title = $(this).attr("title");
        if (title == "beer"){
			$('#search').attr("placeholder", "Beer...");
			$(this).addClass("ui-btn-active");
			$('a[title="venue"]').removeClass("ui-btn-active");
			$('[data-role="collapsible-set"].venues').hide();
			$('[data-role="collapsible-set"].beers').show();			
			search_type = 'beer';
		} else if (title == "venue") {
			$('#search').attr("placeholder", "Venue...");
			$(this).addClass("ui-btn-active");
			$('a[title="beer"]').removeClass("ui-btn-active");
			search_type = 'venue';
			$('[data-role="collapsible-set"].beers').hide();
			$('[data-role="collapsible-set"].venues').show();
		}
    });
});

}).call(this);
