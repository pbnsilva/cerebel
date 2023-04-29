function loadPage(nb, size, isLive, gender, target) {
  toggleSpinner()
  var request = JSON.stringify({Nb: nb, Size: size, IsLive: isLive, Gender: gender});
  $.post("/feededitor/getPage", request, function(data) {
    for(var i=0; i<data.items.length; i++) {
      var item = data.items[i];

      if(item.position !== undefined) {
        continue;
      }

      var products = getProductsArray(item.items);

      var img = $("<img/>").attr("src", item.image_url);

      var addButton = $("<button/>").attr("type", "button").attr("class", "btn btn-outline-success btn-sm").attr("data-id", item.id).attr("data-kind", "add").data("products", products).click(itemButtonHandler).text("Add");
      if(products.length == 0) {
        addButton.prop("disabled", true);
      }

      var matchButton = $("<button/>").attr("type", "button").attr("class", "btn btn-outline-dark btn-sm").attr("data-id", item.id).attr("data-title", item.title).attr("data-date", item.date).attr("data-account", item.source.username).attr("data-image", item.image_url).attr("data-kind", "match").data("products", products).attr("data-target", "#match-modal").click(matchButtonClick).text("Match");

      var buttonsDiv = $("<div/>").attr("class", "img-buttons")
      
      if(target[0].id == "live-content") {
        var removeButton = $("<button/>").attr("type", "button").attr("class", "btn btn-outline-danger btn-sm").attr("data-id", item.id).attr("data-kind", "remove").click(itemButtonHandler).text("Remove");
        buttonsDiv.append(removeButton).append(matchButton);
      } else if(target[0].id == "new-content") {
        var deleteButton = $("<button/>").attr("type", "button").attr("class", "btn btn-danger btn-sm").attr("data-id", item.id).attr("data-kind", "delete").click(itemButtonHandler).text("Delete");
        buttonsDiv.append(addButton).append(matchButton).append(deleteButton);
      }
      
      var imgDiv = $("<div/>").attr("data-id", item.id).attr("class", "col-sm-3 d-inline-block").append(img).append(buttonsDiv);
      
      target.append(imgDiv);
    }
    toggleSpinner();
  });
}

function listSources() {
  $.get("/feededitor/listSources", function(data) {
    var tbody = $("#sources-table tbody");
    tbody.empty()
    data.sources.reverse();
    for(var i=0; i<data.sources.length; i++) {
      var src = data.sources[i];
      var tr = $("<tr/>").append($("<td/>").text(src.url)).append($("<td/>").text(src.type));
      var deleteSourceButton = $("<button>").attr("data-url", src.url).attr("data-type", src.type).attr("type", "button").attr("class", "btn btn-danger delete-source-button").text("Delete source").click(deleteSourceButtonClick);
      tr.append($("<td/>").append(deleteSourceButton));
      tbody.append(tr);
    }
  });
}

function deleteSourceButtonClick() {
  var type = $(this).attr("data-type");
  var url = $(this).attr("data-url");
  $.post("/feededitor/deleteSource", JSON.stringify({Type: type, URL: url}), function(data) {
    listSources();
  });
}

function listPromotions() {
  $.get("/feededitor/listPromotions", function(data) {
    console.log(data.promotions);
    if(data.promotions != null) {
      $("#promotions-content").show();
      var tbody = $("#promotions-table tbody");
      tbody.empty()
      for(var i=0; i<data.promotions.length; i++) {
        var src = data.promotions[i];
        var tr = $("<tr/>").append($("<td/>").append($("<a/>").attr("href", src.items[0].url).text(src.items[0].name))).append($("<td/>").text(src.position));
        var deletePromotionButton = $("<button>").attr("data-product", src.id).attr("type", "button").attr("class", "btn btn-danger delete-promotion-button").text("Delete promotion").click(deletePromotionButtonClick);
        tr.append($("<td/>").append(deletePromotionButton));
        tbody.append(tr);
      }
    } else {
      $("#promotions-table").hide();

    }
  });
}

function deletePromotionButtonClick() {
  var productID = $(this).attr("data-product");
  $.post("/feededitor/deletePromotion", JSON.stringify({product_id: productID}), function(data) {
    listPromotions();
  });
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function matchButtonClick() {
  $(".nav-tabs a[href='#match']").tab('show');
  var button = $(this);
  var productID = button.attr("data-id");
  $("#match-modal-product-id-input").val("");
  $("#match-modal-product-search-input").val("");
  $("#match-modal-search").empty();
  $("#match-modal-error").css("visibility", "hidden");
  $("#match-modal-image").attr("src", button.data("image"));
  $("#match-modal-title").text(button.data("title"));
  $("#match-modal-account").attr("href", "https://www.instagram.com/" + button.data("account")).text(button.data("account"));
  $("#match-modal-date").text(formatDate(button.data("date")));
  $("#match-modal-product-id-input").attr("data-id", productID);
  $("#match-modal-product-id-input").data("products", button.data("products"));
  $("#match-modal-done-button").attr("data-id", productID);
  $("#match-modal-cards").empty();

  var products = button.data("products");
  if(products.length > 0) {
    for(var i=0; i<products.length; i++) {
      addMatchedProductCard(products[i], $("#match-modal-cards"));
    }
    $("#match-modal-done-button").attr("data-products", products);
    $("#match-modal-done-button").prop("disabled", false);
  }

  showSearches(button.data("account"), "", $("#gender-selected").text().toLowerCase(), $("#match-modal-search"));
}

function itemButtonHandler() {
  var button = $(this);
  var kind = button.data("kind");
  var dataID = button.attr("data-id");
  if(kind == "add") {
    if(button.data("products").length == 0) {
        $('button[data-id="' + dataID + '"][data-kind="match"]').trigger("click");
    } else {
      $.post("/feededitor/setIsLive", JSON.stringify({ID: dataID, IsLive: true}), function(data) {
        $('button[data-id="' + dataID + '"][data-kind="add"]').addClass("active");
        $('div[data-id="' + dataID + '"]').remove();
      });
    }
  } else if(kind == "remove") {
    $.post("/feededitor/setIsLive", JSON.stringify({ID: dataID, IsLive: false}), function(data) {
      $('button[data-id="' + dataID + '"][data-kind="remove"]').addClass("active");
      $('div[data-id="' + dataID + '"]').remove();
    });
  } else if(kind == "delete") {
    $.post("/feededitor/deleteItem", JSON.stringify({ID: dataID}), function(data) {
      $('div[data-id="' + dataID + '"]').remove();
    });
  }
}

function toggleSpinner() {
  if ($('#spinner').css('visibility') == 'hidden' )
    $('#spinner').css('visibility','visible');
  else
    $('#spinner').css('visibility','hidden');
}

function formatDate(seconds) {
  var date = new Date(seconds * 1000);
  var month = date.getMonth() + 1;
  return date.getDate() + "-" + month + "-" + date.getFullYear();
}

function getProductsArray(items) {
  var ar = [];
  if(items === null) {
    return ar;
  }

  for(var i=0; i<items.length; i++) {
    var item = items[i];
    ar.push({id: item.id, url: item.url, brand: item.brand, name: item.name, imageURL: item.image_url[0]});
  }
  return ar;
}

function getIDsStringFromItems(items) {
  if(items === null) {
    return "";
  }
  var ids = [];
  for(var i=0; i<items.length; i++) {
    ids.push(items[i].id);
  }
  return ids.join(",");
}

function addMatchedProductCard(product, parentElem) {
  var img = $("<img/>").attr("src", product.imageURL);
  var imgRef = $("<a/>").attr("href", product.url).attr("target", "_blank").append(img);
  var caption = $("<figcaption/>").text(product.name);
  var fig = $("<figure/>").append(imgRef).append(caption);

  var removeButton = $("<button/>").attr("type", "button").attr("class", "btn btn-sm btn-outline-danger").attr("data-id", product.id).data("info", product).text("Remove match").click(removeProductButtonClick);

  var buttonsDiv = $("<div/>").attr("class", "img-buttons")
  buttonsDiv.append(removeButton);
  
  var imgDiv = $("<div/>").attr("id", product.id + "-card").attr("class", "m-3 p-2 d-inline-block border").append(fig).append(buttonsDiv);
  
  parentElem.append(imgDiv);
}

function addSearchProductCard(product, parentElem) {
  var img = $("<img/>").attr("src", product.imageURL);
  var imgRef = $("<a/>").attr("href", product.url).attr("target", "_blank").append(img);
  var caption = $("<figcaption/>").text(product.name);
  var fig = $("<figure/>").append(imgRef).append(caption);

  var addButton = $("<button/>").attr("type", "button").attr("class", "btn btn-outline-success").attr("data-id", product.id).data("info", product).text("Add match").click(addSearchProductButtonClick);

  var buttonsDiv = $("<div/>").attr("class", "img-buttons")
  buttonsDiv.append(addButton);
  
  var imgDiv = $("<div/>").attr("class", "m-3 p-2 d-inline-block border").append(fig).append(buttonsDiv);
  
  parentElem.append(imgDiv);
}

function removeProductButtonClick() {
  var id = $(this).attr("data-id");
  var products = $("#match-modal-product-id-input").data("products");
  var newProducts = [];
  for(var i=0; i<products.length; i++) {
    if(products[i].id === id) {
      continue;
    }
    newProducts.push(products[i]);
  }
  $("#match-modal-product-id-input").data("products", newProducts);
  $("#" + id + "-card").remove();
  setItems();

  if(newProducts.length == 0) {
    $("#match-modal-done-button").prop("disabled", true);
  }
}

function addSearchProductButtonClick() {
  addMatch($(this).data("info").id);
}

function showSearches(brand, text, gender, parentElem) {
  $.ajax({
    type: "POST",
    url: "/feededitor/search",
    dataType: "JSON",
    data: JSON.stringify({brand: brand, text: text, gender: gender}),
    success: function(data) {
      $("#match-modal-search-info").empty();
      if(data.products === null) {
        $("#match-modal-search-info").html($("<p/>").text("No results found!"));
        return;
      }
      for(var i=0; i<data.products.length; i++) {
        var info = data.products[i];
        var product = {id: info.id, name: info.name, brand: info.brand, url: info.url, imageURL: info.image_url[0]};
        addSearchProductCard(product, $("#match-modal-search"));
      }
    },
    error: function(data) {
    }
  });
}

function setItems() {
  var id = $("#match-modal-product-id-input").attr("data-id");
  var products = $("#match-modal-product-id-input").data("products");
  var productsIDs = [];
  for(var i=0; i<products.length; i++) {
    productsIDs.push(products[i].id);
  }
  $.ajax({
    type: "POST",
    url: "/feededitor/setItems",
    dataType: "JSON",
    data: JSON.stringify({ID: id, Items: productsIDs}),
    success: function(res) {
      $('button[data-id="' + id + '"][data-kind="add"]').attr("data-products", $("#match-modal-items-input").val());
      $('button[data-id="' + id + '"][data-kind="match"]').attr("data-products", $("#match-modal-items-input").val());
      $('#match-modal-done-button').attr("data-products", $("#match-modal-items-input").val());
    },
    error: function(res) {
      $("#match-modal-error").css("visibility", "visible");
      $("#match-modal-error").text("ERROR: " + res.responseJSON.message);
    }
  });
  $('button[data-id="' + id + '"]').data("products", products);
}

function addMatch(id) {
  var products = $("#match-modal-product-id-input").data("products");
  for(var i=0; i<products.length; i++) {
    if(id == products[i].id) {
      return;
    }
  }
  $.ajax({
    type: "POST",
    url: "/feededitor/productInfo",
    dataType: "JSON",
    data: JSON.stringify({id: id}),
    success: function(data) {
      var info = data.info;
      var product = {id: info.id, name: info.name, brand: info.brand, url: info.url, imageURL: info.image_url[0]};
      $("#match-modal-product-id-input").data("products").push(product);
      addMatchedProductCard(product, $("#match-modal-cards"));
      setItems();
      $("#match-modal-done-button").prop("disabled", false);
    },
    error: function(data) {
      $("#match-modal-error").css("visibility", "visible");
      $("#match-modal-error").text("ERROR: " + data.responseJSON.message);
    }
  });
}

$(function() {
  var tabCurrentPage = {"live": 1, "new": 1};
  var selectedTab = "new";
  var selectedGender = "all";
  $('a[data-toggle="tab"]').on('shown.bs.tab', function(e) {
    var selected = $(e.target).attr("href").substring(1);
    selectedTab = selected;
    if(selected == "live") {
      $("#live-content").empty();
      tabCurrentPage["live"] = 1;
      loadPage(tabCurrentPage["live"], 20, true, "all", $("#live-content"));
    } else if(selected == "new") {
      $("#new-content").empty();
      tabCurrentPage["new"] = 1;
      loadPage(tabCurrentPage["new"], 20, false, "all", $("#new-content"));

      var removeID = $(".nav-tabs a[href='#new']").data("remove-card-id");
      if(removeID !== undefined) {
        $('div[data-id="' + removeID + '"]').remove();
      }
    } else if(selected == "sources") {
      $("#sources-content").show();
      listSources();
    } else if(selected == "promotions") {
      $("#promotions-content").show();
      listPromotions();
    }
  });

  // dropdowns
  $("#gender-all").click(function (e) {
    e.preventDefault();
    $("#gender-selected").text("All genders");
    $("#match-modal-search").empty();
    showSearches($("#match-modal-account").text(), "",  "all genders", $("#match-modal-search"));
  });
  
  $("#gender-women").click(function (e) {
    e.preventDefault();
    $("#gender-selected").text("Women");
    $("#match-modal-search").empty();
    showSearches($("#match-modal-account").text(), "",  "women", $("#match-modal-search"));
  });
  
  $("#gender-men").click(function (e) {
    e.preventDefault();
    $("#gender-selected").text("Men");
    $("#match-modal-search").empty();
    showSearches($("#match-modal-account").text(), "",  "men", $("#match-modal-search"));
  });

  $(window).on("scroll", function() {
    var scrollHeight = $(document).height();
    var scrollPosition = $(window).height() + $(window).scrollTop();
    if ((scrollHeight - scrollPosition) / scrollHeight === 0) {
      if(selectedTab == "live") {
        loadPage(++tabCurrentPage["live"], 20, true, selectedGender, $("#live-content"));
      } else if(selectedTab == "new") {
        loadPage(++tabCurrentPage["new"], 20, false, "all", $("#new-content"));
      }
    }
  });

  $("#match-modal-product-id-button").click(function() {
    var id = $("#match-modal-product-id-input").val();
    addMatch(id);
  });

  $("#match-modal-back-button").click(function() {
    $(".nav-tabs a[href='#new']").tab('show');
  });
  
  $("#match-modal-done-button").click(function() {
    var button = $(this);
    var dataID = button.attr("data-id");
    if(button.data("products").length > 0) {
      $.post("/feededitor/setIsLive", JSON.stringify({ID: dataID.toString(), IsLive: true}), function(data) {
        console.log('Adding ' + dataID);
        $('div[data-id="' + dataID + '"]').remove();
        $('button[data-id="' + dataID + '"][data-kind="add"]').addClass("active");
        $(".nav-tabs a[href='#new']").attr("data-remove-card-id", dataID);
        $(".nav-tabs a[href='#new']").tab('show');
      });
    }
  });

  $("#match-modal-product-search-button").click(function() {
    var query = $("#match-modal-product-search-input").val();
    $("#match-modal-search").empty();
    showSearches("", query, $("#gender-selected").text().toLowerCase(), $("#match-modal-search"));
  });

  $("#match-modal-product-search-input").keypress(function (e) {
    var key = e.which;
    if(key == 13) {
      $("#match-modal-product-search-button").click();
      return false;  
    }
  });   

  $('#new-content-gender button').click(function() {
    $(this).addClass('active').siblings().removeClass('active');
    $("#live-content").empty();
    selectedGender = $(this).val();
    loadPage(1, 20, true, $(this).val(), $("#live-content"));
  });

  $("#add-source-modal-button").click(function() {
    var url = $("#source-name-input").val();
    $.post("/feededitor/addSource", JSON.stringify({Type: "instagram", URL: url}), function(data) {
      $('#add-source-modal').modal('hide');
      listSources();
    });
  });
  
  $("#add-promotion-modal-button").click(function() {
    var productID = $("#promotion-product-input").val();
    var imageURL = $("#promotion-image-input").val();
    var position = $("#promotion-position-input").val();
    var name = $("#promotion-name-input").val();
    if($.trim(productID) == "" || $.trim(imageURL) == "" || isNaN(parseInt(position, 10)) || $.trim(name) == "") {
      console.log("invalid input");
    } else {
      $.post("/feededitor/addPromotion", JSON.stringify({product_id: productID, image_url: imageURL, position: parseInt(position, 10), name: name}), function(data) {
        $('#add-promotion-modal').modal('hide');
        listPromotions();
      });
    }
  });
  
  $("#sources-content").hide();
  $("#promotions-content").hide();

  loadPage(1, 20, false, "all", $("#new-content"));
});
