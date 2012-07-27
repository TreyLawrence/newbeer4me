(function() {
var ENTER = 13;
var search_count = {'beer' : 0, 'venue' : 0}
var collapsible_left = '<div data-role="collapsible" data-content-theme="c"><h3>';
var collapsible_right = "<img alt='Busy' src='/assets/busy.gif' align='right' ></h3><p>...</p></div>";
var search_type = 'beer';
$(document).ready(function() {
	$("#search_beer").keypress(function(event) {
		if ( event.which == ENTER ) {
			event.preventDefault();
			var text = $('#search_beer').val().trim();
			if ( text ) {
				search_count[search_type] += 1;
				$('#search_beer').val('');
				$(collapsible_left + text + collapsible_right).addClass(search_type+search_count[search_type]).prependTo('[data-role="collapsible-set"]:first');
				$('[data-role="collapsible-set"]').collapsibleset('refresh');
				$.ajaxSetup({
					beforeSend: function(xhr) {
						xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
					}
				});
				$.ajax({
					type: "POST",
					url: "/search",
					//dataType: 'json',
					data: {search: text, id: search_count[search_type], type: search_type}
				}).done(function( msg ) {
					var obj = jQuery.parseJSON(msg);
					$('[data-role="collapsible"].'+obj.type+obj.id).replaceWith(obj.result);
					$('[data-role="collapsible-set"]:first').collapsibleset('refresh');
					if(obj.type == "venue") {
						$('[data-role="collapsible-set"].venue'+obj.id+'_beers').trigger('create').collapsibleset().collapsibleset('refresh');
					}
				});
			}
		}
	});
});

$(function() {
    $("a").click(function(){
        var title = $(this).attr("title");
        if (title == "beer"){
			$(this).addClass("ui-btn-active");
			$('a[title="venue"]').removeClass("ui-btn-active");
			$('[data-role="collapsible"]').remove();
			search_type = 'beer';
		} else if (title == "venue") {
			$(this).addClass("ui-btn-active");
			$('a[title="beer"]').removeClass("ui-btn-active");
			search_type = 'venue';
			$('[data-role="collapsible"]').remove();
		}
    });
});

}).call(this);
