$(function() {

  $("#query-input").on("input", function(e) {
    $.get("/suggesterdemo/suggest?q=" + $("#query-input").val(), function(data) {
      var resDiv = $("#results").empty();
      var suggs = data.response.suggestions;
      for(var i=0; i<suggs.length; i++) {
        var li = $("<li/>").attr("class", "list-group-item").text(suggs[i].value);
        resDiv.append(li);
      }
    });
  });

});
