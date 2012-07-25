(function() {
var ENTER = 13;
var beer_number = 0;
var collapsible_left = '<div data-role="collapsible" data-content-theme="c"><h3>';
var collapsible_right = "<img alt='Busy' src='/assets/busy.gif' align='right' ></h3><p>...</p></div>";
$(document).ready(function() {
	$("#search_beer").keypress(function(event) {
		if ( event.which == ENTER ) {
			event.preventDefault();
			var text = $('#search_beer').val().trim();
			if ( text ) {
				beer_number++;
				$('#search_beer').val('');
				$(collapsible_left + text + collapsible_right).prependTo('[data-role="collapsible-set"]');
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
					data: {search: text, id: beer_number}
				}).done(function( msg ) {
					var obj = jQuery.parseJSON(msg);
					$('[data-role="collapsible"]').eq(obj.id - beer_number).replaceWith(obj.result);
					$('[data-role="collapsible-set"]').collapsibleset('refresh');
				});
			}
		}
	});
});

}).call(this);
