function clearAllValues() {
  $("#top-terms-table").empty();
  $("#empty-terms-table").empty();
  $("#top-terms-pagination-ul").empty();
  $("#empty-terms-pagination-ul").empty();
  $("#annotation-coverage-table").empty();

  $("#new-users-count-value").text("-");
  $("#total-users-count-value").text("-");
  $("#active-new-users-count-value").text("-");
  $("#active-users-count-value").text("-");
  $("#sessions-count-value").text("-");
  $("#search-count-value").text("-");
  $("#search-clickout-rate-value").text("-");
  $("#freshlooks-clickout-rate-value").text("-");
  $("#notifications-sent-count-value").text("-");
  $("#notifications-open-count-value").text("-");
  $("#notifications-open-rate-value").text("-");
  $("#engagement-actions-per-user-value").text("-");
  $("#product-count-value").text("-");
  $("#brand-count-value").text("-");
  $("#checkouts-value").text("-");
  $("#gmv-value").text("-");
  
  $("#new-users-count-diff").text("-");
  $("#checkouts-diff").text("-");
  $("#gmv-diff").text("-");
  $("#total-users-count-diff").text("-");
  $("#active-new-users-count-diff").text("-");
  $("#active-users-count-diff").text("-");
  $("#sessions-count-diff").text("-");
  $("#search-count-diff").text("-");
  $("#search-clickout-rate-diff").text("-");
  $("#freshlooks-clickout-rate-diff").text("-");
  $("#notifications-sent-count-diff").text("-");
  $("#notifications-open-count-diff").text("-");
  $("#engagement-actions-per-user-diff").text("-");
}

function loadValues(startDate, endDate) {
  clearAllValues();
  var startDateStr = startDate.getFullYear() + ("0" + (startDate.getMonth() + 1)).slice(-2) + ("0" + startDate.getDate()).slice(-2);
  var endDateStr = endDate.getFullYear() + ("0" + (endDate.getMonth() + 1)).slice(-2) + ("0" + endDate.getDate()).slice(-2);
  $.get("/analytics/metrics?startDate=" + startDateStr + "&endDate=" + endDateStr, function(data) {
    var values = data.values;

    $("#new-users-count-value").text(values.new_users_count);
    $("#total-users-count-value").text(values.total_users_count);
    $("#active-new-users-count-value").text(values.active_new_users_count);
    $("#active-users-count-value").text(values.active_users_count);
    $("#sessions-count-value").text(values.sessions_count);
    $("#search-count-value").text(values.searches_count);
    $("#search-clickout-rate-value").text(values.search_clickout_rate_mean);
    $("#freshlooks-clickout-rate-value").text(values.freshlooks_clickout_rate_mean);
    $("#notifications-sent-count-value").text(values.notifications_sent_count);
    $("#notifications-open-count-value").text(values.notifications_open_count);
    $("#notifications-open-rate-value").text(values.notifications_open_rate_mean);
    $("#engagement-actions-per-user-value").text(values.engagement_actions_per_user_mean);
    $("#product-count-value").text(values.product_count);
    $("#brand-count-value").text(values.brand_count);
    $("#checkouts-value").text(values.checkouts_total);
    $("#gmv-value").text(values.gmv_total);
   
    displayDiff(values.new_users_count_diff, $("#new-users-count-diff"));
    displayDiff(values.total_users_count_diff, $("#total-users-count-diff"));
    displayDiff(values.active_new_users_count_diff, $("#active-new-users-count-diff"));
    displayDiff(values.active_users_count_diff, $("#active-users-count-diff"));
    displayDiff(values.sessions_count_diff, $("#sessions-count-diff"));
    displayDiff(values.searches_count_diff, $("#search-count-diff"));
    displayDiff(values.search_clickout_rate_diff, $("#search-clickout-rate-diff"));
    displayDiff(values.freshlooks_clickout_rate_diff, $("#freshlooks-clickout-rate-diff"));
    displayDiff(values.notifications_sent_count_diff, $("#notifications-sent-count-diff"));
    displayDiff(values.notifications_open_count_diff, $("#notifications-open-count-diff"));
    displayDiff(values.engagement_actions_per_user_diff, $("#engagement-actions-per-user-diff"));
    displayDiff(values.checkouts_total_diff, $("#checkouts-diff"));
    displayDiff(values.gmv_total_diff, $("#gmv-diff"));

    $("#top-terms-table").data("terms", values.searches);
    showSearchTermsPage(1, $("#top-terms-table"));
    showSearchTermsPagination(1, $("#top-terms-table"), $("#top-terms-pagination-ul"));
    
    $("#empty-terms-table").data("terms", values.empty_searches);
    showSearchTermsPage(1, $("#empty-terms-table"));
    showSearchTermsPagination(1, $("#empty-terms-table"), $("#empty-terms-pagination-ul"));

    $("#annotation-coverage-table").data("coverage", values.annotation_coverage);
    showAnnotationCoverageTable($("#annotation-coverage-table"));

    if($("#date-selected").text() != "Yesterday") {
      showBarChart(values.engagement_actions_per_user, 'Engagement actions per user', 'engagement-actions-per-user-chart');
      showBarChart(values.return_rate, '7-day return rate', 'return-rate-chart');
      showBarChart(values.search_clickout_rate, 'Search clickout rate', 'search-clickout-rate-chart');
      showBarChart(values.freshlooks_clickout_rate, 'Freshlooks clickout rate', 'freshlooks-clickout-rate-chart');
      showBarChart(values.new_product_count, 'New products', 'new-products-chart');
      showBarChart(values.checkouts, 'Checkouts', 'checkouts-chart');
      showBarChart(values.gmv, 'GMV (euros)', 'gmv-chart');
      showBarChart(values.three_month_retention_rate, '3-month retention rate', 'three-month-retention-rate-chart');
    }
  });
}

function displayDiff(value, el) {
  if(value > 0) {
    el.html($("<font/>").attr("style", "color:green").html("&uarr;&nbsp;" + value + "%"));
  } else if(value < 0) {
    el.html($("<font/>").attr("style", "color:red").html("&darr;&nbsp;" + value + "%"));
  }
}

function canLoad() {
  $("#date-last-week").trigger("click");
}

function showBarChart(y, title, elemName) {
  var data = new google.visualization.DataTable();
  data.addColumn('number');
  data.addColumn('number');
  for(var i=0; i<y.length; i++) {
    data.addRow([i, y[i]]);
  }

  var options = {
    'title': title,
    'legend': {position: 'none'},
    chartArea: {width: '75%', height: '70%'},
    vAxis: {minValue: 0},
    colors: ['#3685b3'],
  };

  var chart = new google.visualization.ColumnChart(document.getElementById(elemName));
  chart.draw(data, options);
}

function showSearchTermsPage(page, tableElem) {
  var terms = tableElem.data("terms");
  
  tableElem.empty();

  if(terms.length > 0) {
    var tableHead = $("<thead/>").append($("<tr/>").append($("<th/>").attr("scope", "col").text("Query")).append($("<th/>").attr("scope", "col").text("Count")));
    tableElem.append(tableHead);
  
    var tableBodyElem = $("<tbody/>");
    var start = (page - 1) * 5;
    for(var i=start; i<Math.min(terms.length, 5 + start); i++) {
      var term = terms[i];
      tableBodyElem.append($("<tr/>").append($("<td/>").text(term.term)).append($("<td/>").text(term.count)));
    }
    tableElem.append(tableBodyElem);
  } else {
    tableElem.append($("<tr/>").append($("<td/>").text("No data.")));
  }  
}

function showSearchTermsPagination(from, tableElem, ulElem) {
  var terms = tableElem.data("terms");

  ulElem.empty();
  
  var pageCount = Math.ceil(terms.length/5);
  var start = from - 1;

  if(start > 1) {
    ulElem.append($("<li/>").attr("data-page", "prev").attr("class", "page-item").append($("<a/>").attr("class", "page-link").click(pageLinkClick).text("<<")));
  }
  
  for(var i=start; i<Math.min(pageCount, 5 + start); i++) {
    var li = $("<li/>").attr("data-page", i+1).append($("<a/>").attr("class", "page-link").click(pageLinkClick).text(i+1));
    if(i == start) {
      li.attr("class", "page-item active");
    } else {
      li.attr("class", "page-item");
    }
    ulElem.append(li);
  }
    
  if(pageCount > start + 5) {
    ulElem.append($("<li/>").attr("data-page", "next").attr("class", "page-item").append($("<a/>").attr("class", "page-link").click(pageLinkClick).text(">>")));
  }  
}

function showAnnotationCoverageTable(tableElem) {
  var ans = tableElem.data("coverage");
  
  tableElem.empty();

  var tableHead = $("<thead/>").append($("<tr/>").append($("<th/>").attr("scope", "col").text("Annotation")).append($("<th/>").attr("scope", "col").text("Coverage (%)")));
  tableElem.append(tableHead);

  var tableBodyElem = $("<tbody/>");
  for(var k in ans) {
    tableBodyElem.append($("<tr/>").append($("<td/>").text(k)).append($("<td/>").text(ans[k].toFixed(2))));
  }

  tableElem.append(tableBodyElem);
}

function pageLinkClick() {
  var page = $(this).parent().data("page");
  var tableElem = $(this).parent().parent().parent().parent().parent().find("div table");
  if(page == "next") {
    showSearchTermsPagination($(this).parent().prev().data("page"), tableElem, $(this).parent().parent());
  } else if(page == "prev") {
    showSearchTermsPagination(Math.max($(this).parent().next().data("page") - 5, 1), tableElem, $(this).parent().parent());
  } else {
    showSearchTermsPage(page, tableElem);
    $(this).parent().parent().find("li.active").removeClass("active");
    $(this).parent().addClass("active");
  }
}

$(function() {
  // Load the Visualization API and the corechart package.
  google.charts.load('current', {'packages':['corechart']});
  google.charts.setOnLoadCallback(canLoad);

  $("#date-yesterday").click(function() {
    var startDate = new Date();
    startDate.setDate(startDate.getDate() - 1);
    var endDate = new Date();
    loadValues(startDate, endDate);
    $("#date-selected").text("Yesterday");
  });
  
  $("#date-last-week").click(function() {
    var startDate = new Date();
    startDate.setDate(startDate.getDate() - 7);
    var endDate = new Date();
    loadValues(startDate, endDate);
    $("#date-selected").text("Last 7 days");
  });
  
  $("#date-last-month").click(function() {
    var startDate = new Date();
    startDate.setDate(startDate.getDate() - 30);
    var endDate = new Date();
    loadValues(startDate, endDate);
    $("#date-selected").text("Last 30 days");
  });
});
