var annotationData = {}
var activeTab = "labels";

function drawBarChart(data) {
    var dataTable = new google.visualization.arrayToDataTable(data);

    var height = $('tabContent').height();
    var width = $('tabContent').width() - 50; // minus padding

    var options = {
        width: width,
        height: height,
        colors: ['#B9B9B9'],
        legend: {
            position: 'none'
        },
        hAxis: {
            'gridlines': {
                'color': 'none'
            },
            'textPosition': 'none'
        },
        bars: 'horizontal', // Required for Material Bar Charts.
        axes: {
            x: {
                0: {
                    side: 'top',
                    label: 'Percentage'
                } // Top x-axis.
            }
        },
        bar: {
            groupWidth: "100%"
        }
    };

    var chart = new google.charts.Bar(document.getElementById('tabContent'));
    chart.draw(dataTable, options);
};

function showLabels() {
    var data = [
        ['', '']
    ];
    annotationData.category_annotations.forEach(function (label) {
        data.push([label.label, label.confidence * 100]);
    });

    google.charts.load('current', {
        'packages': ['bar']
    });

    google.charts.setOnLoadCallback(function () {
        drawBarChart(data);
    });
}

function showTexture() {
    var data = [
        ['', '']
    ];
    annotationData.texture_annotations.forEach(function (label) {
        data.push([label.label, label.confidence * 100]);
    });

    google.charts.load('current', {
        'packages': ['bar']
    });

    google.charts.setOnLoadCallback(function () {
        drawBarChart(data);
    });
}

// Render Colors Start

var rgbToHex = function (rgb) {
    var hex = Number(rgb).toString(16);
    if (hex.length < 2) {
        hex = "0" + hex;
    }
    return hex;
};

var fullColorHex = function (r, g, b) {
    var red = rgbToHex(r);
    var green = rgbToHex(g);
    var blue = rgbToHex(b);
    return red + green + blue;
};

function showColors() {
    html = '<h4>Relevant colors</h4><p><div style="width:100%">';
    annotationData.color_annotations.forEach(function (color) {
        color = "#" + fullColorHex(parseInt(color.center[0] * 255), parseInt(color.center[1] * 255), parseInt(color.center[2] * 255));
        html += '<div style="height:50px;float:left;margin-right:25px;width:50px;background-color:' + color + '"></div>'
    });
    html += '</p></div>';
    document.getElementById('tabContent').innerHTML = html;
}

// Render Colors End

function showJSON() {
    var html = '<div style="overflow-y: auto;">' + jsonPrettyPrint.toHtml(annotationData) + '</div>';
    $('#tabContent').html(html);

}

function switchTab(newTab) {
    var oldTab = activeTab;
    activeTab = newTab
    switch (newTab) {
        case 'labels':
            showLabels()
            break;
        case 'color':
            showColors()
            break;
        case 'patterns':
            showTexture()
            break;
        case 'json':
            showJSON()
            break;
    }
}

function showAnnotations() {
    $('#uploadFile').hide()
    $('#newUpload').show();
    $('#annotations').show()
    showLabels()
}

function resetAnnotations() {
    $('#uploadFile').show()
    $('#newUpload').hide();
    $('#annotations').hide()
    $("#imageUploadform")[0].reset();
}

// Image Upload Handler Start
// ************************ Drag and drop ***************** //
var dropArea = document.getElementById("drop-area");

['dragenter', 'dragover', 'dragleave', 'drop'].forEach(function (eventName) {
    dropArea.addEventListener(eventName, preventDefaults, false)
});

// Handle dropped files
dropArea.addEventListener('drop', handleDrop, false)

function preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
}

function handleDrop(e) {
    var dt = e.dataTransfer
    var files = dt.files

    handleFiles(files)
}

function handleFiles(files) {
    Array.prototype.forEach.call(files, function (file) {
        uploadFile(file);
        previewFile(file);

    });
}

function previewFile(file) {
    var reader = new FileReader()
    reader.readAsDataURL(file)
    reader.onloadend = function () {
        // delete previous images if any
        if (document.getElementById('uploadImageContainer').hasChildNodes()) {
            document.getElementById('uploadImageContainer').removeChild(document.getElementById('uploadImageContainer').childNodes[0]);
        }
        // render current
        var img = document.createElement('img')
        img.src = reader.result
        document.getElementById('uploadImageContainer').appendChild(img)
    }
}

function uploadFile(file, i) {
    var url = '/visiondemo/annotate';
    var xhr = new XMLHttpRequest()
    var formData = new FormData()
    xhr.open('POST', url, true)
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
    $('.loader').show();
    $('#imageHint').hide();
    xhr.addEventListener('readystatechange', function (e) {
        $('.loader').hide();
        $('#imageHint').show();
        if (xhr.readyState == 4 && xhr.status == 200) {
            var myArr = JSON.parse(xhr.responseText);
            annotationData = myArr.response;
            showAnnotations()
        } else if (xhr.readyState == 4 && xhr.status != 200) {
            // Error. Inform the user
            console.log("error");
        }
    })

    formData.append('file', file)
    xhr.send(formData)

}

// Image Upload Handler End

$(document).ready(function () {
    // setup handler for tabs
    $('#tabMenu a').click(function () {
        event.preventDefault();
        switchTab($(this).data("id"));
    });
    $('#newUpload').click(function () {
        event.preventDefault()
        resetAnnotations();
    });
});


var jsonPrettyPrint = {
    replacer: function (match, pIndent, pKey, pVal, pEnd) {
        var key = '<span class=json-key>';
        var val = '<span class=json-value>';
        var str = '<span class=json-string>';
        var r = pIndent || '';
        if (pKey)
            r = r + key + pKey.replace(/[": ]/g, '') + '</span>: ';
        if (pVal)
            r = r + (pVal[0] == '"' ? str : val) + pVal + '</span>';
        return r + (pEnd || '');
    },
    toHtml: function (obj) {
        var jsonLine =
            /^( *)("[\w]+": )?("[^"]*"|[\w.+-]*)?([,[{])?$/mg;
        return JSON.stringify(obj, null, 3)
            .replace(/&/g, '&amp;').replace(/\\"/g, '&quot;')
            .replace(/</g, '&lt;').replace(/>/g, '&gt;')
            .replace(jsonLine, jsonPrettyPrint.replacer);
    }
};
