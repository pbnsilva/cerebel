function doSearch(query, gender, curPage) {
  toggleSpinner();

  var searchResultsDiv = $("#search-results");
  var annotationsDiv = $("#query-annotations");

  if(curPage == 1) {
    searchResultsDiv.empty()
  }

  var request = JSON.stringify({query: query, gender: gender, page: curPage, use_beta_search: useBetaSearch()});
  $.post("/searchdemo/search", request, function(data) {
    console.log("Took: ", data.response.took / 1000);
    if(data.response.matches.total == 0) {
      searchResultsDiv.append($("<p/>").text("No results found."));
    } else {
      if(data.response.matches.items !== undefined) {
        var items = data.response.matches.items;
        for(var i=0; i<items.length; i++) {
          addResultCard(items[i], searchResultsDiv);
        }
      }
    }
    
    annotationsDiv.empty();
    var entities = data.response.query.entities;
    for(var i=0; i<entities.length; i++) {
      var label = $("<span/>").attr("class", "badge badge-info mr-2").text(entities[i].value);
      annotationsDiv.append(label);
    }
    toggleSpinner();
  });
}

function toggleSpinner() {
  if ($('#spinner').css('visibility') == 'hidden' )
    $('#spinner').css('visibility','visible');
  else
    $('#spinner').css('visibility','hidden');
}

function cardClick() {
  if(!isEditMode()) {
    window.open($(this).data("url"), "_blank");
    return;
  }

  var card = $(this);
  var isSelected = card.attr("data-selected") == "true";
  if(isSelected) {
    card.removeClass("border");
    card.removeClass("border-primary");
    card.attr("style", "max-height: 16rem; float:left;");
    card.attr("data-selected", false);
  } else {
    card.attr("class", "card m-2 border border-primary");
    card.attr("style", "max-height: 16rem; float:left; border-width:4px !important;");
    card.attr("data-selected", true);
  }

  updatePanel();
}

function addResultCard(item, parentElem) {
  var annotations = item.annotations;
  var img = $("<img>").attr("style", "max-height: 16rem;").attr("src", item.image_url[0]).append(img);
  var card = $("<div/>").attr("class", "card m-2").attr("style", "max-height: 16rem; float:left;").data("annotations", annotations).attr("data-selected", false).attr("data-product-id", item.id).data("url", item.share_url).append(img).click(cardClick);
  parentElem.append(card);
}

function updatePanel() {
  var ids = [];
  var attrs = {};
  $('#search-results div[data-selected=true]').each(function(i,e) {
    ids.push($(e).attr("data-product-id"));
    var anns = $(e).data("annotations");
    for(var k in $(e).data("annotations")) {
      if(k === "brand") {
        continue;
      }
      if(!(k in attrs)) {
        attrs[k] = [];
      }
      var ank = $(e).data("annotations")[k];
      for(var i=0; i<ank.length; i++) {
        if(attrs[k].indexOf(ank[i]) == -1) {
          attrs[k].push(ank[i]);
        }
      }
    }
  });
  
  var panel = $("#edit-content");
  panel.empty();

  if(ids.length == 0) {
    return;
  }

  var opts = ["category", "color", "color_count", "fabric", "gender", "heel_form", "length", "occasion", "pattern", "season",
    "shirt_collar", "shoe_fastener", "trouser_rise"];
  for(var i=0; i<opts.length; i++ ){
    var k = opts[i];
    var div = $("<div/>").attr("class", "form-group");
    var label = $("<label/>").attr("for", k).text(k);
    var input = $("<input>").attr("id", k).attr("class", "form-control");
    if(k in attrs) {
      input.val(attrs[k].join(","));
    }
    div.append(label).append(input)
    panel.append(div);
  }

  var updateButton = $("<button/>").attr("type", "button").attr("class", "btn btn-primary").text("Update").data("ids", ids).click(updateButtonClick);
  panel.append(updateButton);
}

function updateButtonClick() {
  var btn = $(this);
  var ids = btn.data("ids");
  var attrs = {};
  $("#edit-content input").each(function(i, e) {
    var el = $(e);
    if(el.val().length > 0) {
      attrs[el.attr("id")] = el.val().split(",");
    }
  });
  
  var request = JSON.stringify({ids: ids, annotations: attrs});
  $.ajax({
    type: "POST",
    url: "/searchdemo/update",
    dataType: "JSON",
    data: request,
    success: function(data) {
      $('#search-results div[data-selected=true]').each(function(i,e) {
        $(e).trigger("click");
      });
      console.log("success");
    },
    error: function(data) {
      console.log("error");
    }
  });
}

function isEditMode() {
  var urlParams = new URLSearchParams(window.location.search);
  return urlParams.get("edit") == "1";
}

function useBetaSearch() {
  var urlParams = new URLSearchParams(window.location.search);
  return urlParams.get("beta") == "1";
}

function getQueryParam() {
  var urlParams = new URLSearchParams(window.location.search);
  return urlParams.get("q");
}

$(function() {
  var curPage = 0;

  $("#search-button").click(function() {
    curPage = 1;
    doSearch($("#query-input").val(), "", curPage);
  });
  
  $("#query-input").on("keydown", function(e) {
    if(e.which == 13) {
      $("#search-button").trigger("click");
    };
  });
  
  $(window).on("scroll", function() {
    var scrollHeight = $(document).height();
    var scrollPosition = $(window).height() + $(window).scrollTop();
    if ((scrollHeight - scrollPosition) / scrollHeight === 0) {
      doSearch($("#query-input").val(), "", ++curPage);
    }
  });

  $("#query-input").focus();

  var q = getQueryParam();
  if(q == null) {
    q = "black dress";
  }

  $("#query-input").val(q);
  $("#search-button").trigger("click");
});
