function listSpiders() {
  $.get("/scrapers/listSpiders", function(data) {
    var tbody = $("#spiders-table tbody");
    tbody.empty()

    for(var i=0; i<data.spiders.length; i++) {
      var spider = data.spiders[i];
      var runButton = $("<button>").attr("id", spider).attr("type", "button").attr("class", "btn btn-info run-job-button").text("Run job").click(runJobButtonClick);
      var deleteButton = $("<button>").attr("id", spider).attr("type", "button").attr("class", "btn btn-danger delete-products-button").text("Delete products").click(deleteProductsButtonClick);
      var tr = $("<tr/>").append($("<td/>").text(spider)).append($("<td/>").append(runButton).append(deleteButton));
      tbody.append(tr);
    }
  });
}

function listJobs() {
  $.get("/scrapers/listJobs", function(data) {
    for(var k in data.jobs) {
      var jobs = data.jobs[k];

      k = k.toLowerCase();
      $("#" + k + "-jobs-badge").text(jobs.length);

      var tbody = $("#" + k + "-jobs-table tbody");
      tbody.empty()
      for(var i=0; i<jobs.length; i++) {
        var job = jobs[i];
        var viewLogsButton = $("<button>").attr("id", job.id).attr("data-spider", job.spider).attr("type", "button").attr("class", "btn btn-info view-logs-button").text("View logs").attr("data-toggle", "modal").attr("data-target", "#log-modal").click(viewLogsButtonClick);
        var tr = $("<tr/>").append($("<td/>").text(job.id)).append($("<td/>").text(job.spider)).append($("<td/>").text(job.start_time)).append($("<td/>").text(job.end_time)).append($("<td/>").html(getIndexedBadge(job.indexed)));
        if(k !== "finished") {
          var cancelJobButton = $("<button>").attr("id", job.id).attr("type", "button").attr("class", "btn btn-danger cancel-job-button").text("Cancel job").click(cancelJobButtonClick);
          tr.append($("<td/>").append(viewLogsButton).append(cancelJobButton));
        } else {
          tr.append($("<td/>").append(viewLogsButton));
        }
        tbody.append(tr);
      }
    }
  });
}

function getIndexedBadge(nb) {
  if(nb < 0) {
    return '<span class="badge badge-secondary">'+nb+'</span>';
  } else if (nb == 0) {
    return '<span class="badge badge-danger">'+nb+'</span>';
  }
  return '<span class="badge badge-success">'+nb+'</span>';
}


function scheduleJob(spider) {
  $.ajax({
    type: "POST",
    url: "/scrapers/scheduleJob",
    dataType: "JSON",
    data: JSON.stringify({spider: spider}),
    success: function(data) {
    },
    error: function(data) {
    }
  });
}

function cancelJob(id) {
  $.ajax({
    type: "POST",
    url: "/scrapers/cancelJob",
    dataType: "JSON",
    data: JSON.stringify({jobid: id}),
    success: function(data) {
    },
    error: function(data) {
    }
  });
}

function runJobButtonClick() {
  var id = $(this).attr("id");
  scheduleJob(id);
}

function deleteProductsButtonClick() {
  var button = $(this);
  button.prop("disabled", true);
  var id = $(this).attr("id");
  $.post("/scrapers/deleteProducts", JSON.stringify({spider: id}), function() {
    button.prop("disabled", false);
  });
}

function cancelJobButtonClick() {
  var id = $(this).attr("id");
  cancelJob(id);
}

function viewLogsButtonClick() {
  var id = $(this).attr("id");
  var spider = $(this).attr("data-spider");
  $.get("/scrapers/getLogs?spider=" + spider + "&id=" + id, function(data) {
    $("#log-modal-body").text(data.text);
  });
}

$(function() {
  listSpiders();
  $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    var target = $(e.target).attr("href");
    if(target == '#spiders') {
      listSpiders();
    } else if(target == '#jobs') {
      listJobs();
    }
  });

  setInterval(function() {
    var tab = $("#myTab li a.active").attr("href");
    if(tab === "#jobs") {
      listJobs();
    }
  },4000);
});
