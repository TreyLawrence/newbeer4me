$(document).ready(function() {
var ENTER = 13;

var search_count = {'beer' : 0, 'venue' : 0}
var search_type = 'beer';

var collapsible_left_busy = '<div data-role="collapsible" data-content-theme="c"><h3>';
var collapsible_right_busy = "<img alt='Busy' src='/assets/busy.gif' align='right' ></h3><p>...</p></div>";
var collapsible_left_timeout = '<div data-role="collapsible" data-content-theme="c"><h3>Search timed out</h3><p>Searched for ';
var collapsible_right_timeout = '</p></div>'

$(function() {
	$("#search").live("keypress", function(event) {
		if ( event.which == ENTER ) {
			event.preventDefault();
			var text = $('#search').val().trim();
			if ( text ) {
				search_count[search_type] += 1;
				$('#search').val('');
				$(collapsible_left_busy + text + collapsible_right_busy)
						.addClass(search_type+search_count[search_type])
						.prependTo('[data-role="collapsible-set"].'+search_type+'s');
				$('[data-role="collapsible-set"].'+search_type+'s').collapsibleset('refresh');
				ajax_send(text, search_count[search_type], search_type);
			}
		}
	});
});

$(function() {
	$('a[data-icon="refresh"]').live("click", function(){
		var name = $(this).attr("search_name");
		var id = $(this).attr("search_id");
		var type = $(this).attr("search_type");

		var busy_collapsible = $(collapsible_left_busy + name + collapsible_right_busy)
				.addClass(type+id);
		$('[data-role="collapsible"].'+type+id).replaceWith(busy_collapsible);
		$('[data-role="collapsible-set"].'+type+'s').collapsibleset('refresh');

		ajax_send(name, id, type);
	});
    $('a[title="beer"]').live("click", function(){
		$(this).addClass("ui-btn-active");
		$('a[title="venue"]').removeClass("ui-btn-active");
		$('#search').attr("placeholder", "Beer...");
		$('[data-role="collapsible-set"].venues').hide();
		$('[data-role="collapsible-set"].beers').show();
		search_type = 'beer';
	});
	$('a[title="venue"]').live("click", function(){
		$(this).addClass("ui-btn-active");
		$('a[title="beer"]').removeClass("ui-btn-active");
		$('#search').attr("placeholder", "Venue...");
		$('[data-role="collapsible-set"].beers').hide();
		$('[data-role="collapsible-set"].venues').show();
		search_type = 'venue';
    });
	$('a.foursquare').live("click", function(){
		$(this).replaceWith($(document.createElement("img")).attr("src","/assets/foursquare-busy.gif"));
		window.location = "https://foursquare.com/oauth2/authenticate" +
                    "?client_id=DLTI5SNFPYNXCV4AKZYYPZWXOFWLS3B2ZBGOWEC1DB1NO3BJ" +
                    "&response_type=code" +
                    "&redirect_uri=https://newbeer4me.herokuapp.com/enable"
	});
});


function ajax_send(text, id_num, search_type){
	if(search_type == "beer") {
		var timeout_time = 30000; //30 seconds for beers
	} else {
		var timeout_time = 60000; //60 seconds for venues
	}

	$.ajaxSetup({
		beforeSend: function(xhr) {
			xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
		}
	});
	$.ajax({
		type: "POST",
		url: "/search",
		dataType: "json",
		timeout: timeout_time,
		data: {search: text, id: id_num, type: search_type}
	}).done(function( msg ) {
		$('[data-role="collapsible"].'+msg.type+msg.id).replaceWith(msg.result);
		$('[data-role="collapsible-set"].'+msg.type+'s').collapsibleset('refresh');
		if(msg.type == "venue") {
			$('[data-role="collapsible-set"].venue'+msg.id+'_beers_had')
					.trigger('create')
					.collapsibleset()
					.collapsibleset('refresh');
			$('[data-role="collapsible-set"].venue'+msg.id+'_beers_nothad')
					.trigger('create')
					.collapsibleset()
					.collapsibleset('refresh');
		}
	}).error(function(jqXHR, textStatus, errorThrown) {
		if(textStatus==="timeout") {
            var data = params_unserialize(this.data);
			var button = $("<a>").attr("href", "#")
		            .attr("data-role", "button")
		            .attr("data-icon", "refresh")
		 			.attr("data-iconpos", "notext")
					.attr("search_type", data.type)
					.attr("search_id", data.id)
					.attr("search_name", data.search)
					.buttonMarkup({ inline: true })
					.button();
			var new_collapsible = $(collapsible_left_timeout + data.search + collapsible_right_timeout)
					.addClass(data.type+data.id);
					
			button.appendTo(new_collapsible.find('p'));

			$('[data-role="collapsible"].'+data.type+data.id).replaceWith(new_collapsible);
			$('[data-role="collapsible-set"].'+data.type+'s').collapsibleset('refresh');
        }
    });
}

function params_unserialize(p){
	var ret = {},
    seg = p.replace(/^\?/,'').replace(/\+/,' ').split('&'),
    len = seg.length, i = 0, s;
	for (;i<len;i++) {
	    if (!seg[i]) { continue; }
	    s = seg[i].split('=');
	    ret[s[0]] = s[1];
	}
	return ret;
}

});
