$(function() {
  $("#saveButton").click(function() {
    let data = {
      ID: $(this).attr("data-brandid")
    };

    if ($("#nameInput").val() != "") {
      data.Name = $("#nameInput").val();
    }

    if ($("#urlInput").val() != "") {
      data.URL = $("#urlInput").val();
    }

    if ($("#descriptionInput").val() != "") {
      data.Description = $("#descriptionInput").val();
    }

    if ($("#locationInput").val() != "") {
      data.Location = $("#locationInput").val();
    }

    if ($("#priceRangeInput").val() != "") {
      data.Price_Range = $("#priceRangeInput").val();
    }

    if ($("#tagsInput").val() != "") {
      data.Tags = $("#tagsInput").val().split(",");
    }

    $.post("/brandpages/"+data.ID+"/update", JSON.stringify(data), function(resp) {
      console.log(resp);
      window.location.href = "/brandpages";
    });
  });

  $("#backButton").click(function() {
    window.location.href = "/brandpages";
  });
});
