/*

Faer agent implementation for DialogFlow 1.0

Status: In use

*/
'use strict';

const functions = require('firebase-functions'); // Cloud Functions for Firebase library
const DialogflowApp = require('actions-on-google').DialogflowApp; // Google Assistant helper library

const FaerCerebelAPIToken = "toxZfAFGScYxMwfkhJbAlZSOWPrTGu";
const Cerebel = require('cerebel-api'); // Interface for Cerebel Search API
const apiHandler = new Cerebel(FaerCerebelAPIToken);

exports.faerDialogflowFirebaseFulfillment = functions.https.onRequest((req, res) => {
    console.log('Dialogflow Request headers: ' + JSON.stringify(req.headers));
    console.log('Dialogflow Request body: ' + JSON.stringify(req.body));

    const app = new DialogflowApp({
        request: req,
        response: res
    });

    // Create functions to handle requests here
    const OPTION_ACTION = 'option.select';
    const SUGGESTIONS_ACTION = "input.suggestions";
    const SEARCH_ACTION = "input.search";
    const SHOWSIMILAR_ACTION = "action.showsimilarproducts";
    // context
    const OUT_CONTEXT = 'output_context';
    const LAST_PRODUCTID_ARG = 'lastProductId';
    const GENDER_ARG = 'gender';

    function optionIntent(app) {
        // Get the user's selection
        const key = app.getContextArgument('actions_intent_option', 'OPTION').value;
        apiHandler.product(key).then((result) => {
            console.log("optionIntent", key, result);
            if ((typeof result.records === 'undefined') || (result.records.length == 0)) {
                app.ask(noResultCard(app));
                return
            }
            const parameters = {};
            parameters[LAST_PRODUCTID_ARG] = result.records[0].id;
            app.setContext(OUT_CONTEXT, 1, parameters);
            app.ask(productCard(app, result.records[0]));
        }).catch((error) => {
            console.log(error);
            app.tell(error);
        });
    }

    function suggestionsIntent(app) {
        let gender = app.getArgument('gender');
        apiHandler.freshLooks(gender).then((result) => {
            console.log("suggestionsIntent", result, gender);
            if ((typeof result.records === 'undefined') || (result.records.length == 0)) {
                app.ask(noResultCard(app));
                return
            }
            // build suggestion chips
            var all_items = [];
            result.records.forEach(function (record) {
                if (typeof record.items !== 'undefined') {
                    all_items = all_items.concat(record.items);
                };
            });
            let inputPrompt = app.buildRichResponse().addSimpleResponse('Here are some suggestions for you').addSuggestions(suggestionsFromAnnotations(all_items));
            // answer
            app.askWithCarousel(inputPrompt, freshLooksCarousel(app, result.records));

        }).catch((error) => {
            console.log(error);
            app.tell(error);
        });
    }

    function searchIntent(app) {
        let query = app.getArgument('query');
        let gender = app.getArgument('gender');
        console.log("gender", query, gender);
        apiHandler.search(query, gender).then((result) => {
            if ((typeof result.records === 'undefined') || (result.records.length == 0)) {
                if (typeof result.query_annotations !== 'undefined') {
                    app.ask(noResultCard(app));
                }
                app.ask(unknownQueryCard(app));
                return
            }
//            let inputPrompt = app.buildRichResponse().addSimpleResponse('Here is what I found for you').addSuggestions(suggestionsFromAnnotations(result.records));
            let inputPrompt = app.buildRichResponse().addSimpleResponse('Here is what I found for you').addSuggestions(["Sneaker", "Jeans", "Ok, Goodbye"]);
            console.log("contexts", app.getContexts());

            // answer
            console.log("arg", app.getContextArgument(OUT_CONTEXT, LAST_PRODUCTID_ARG));
            const parameters = {};
            parameters[GENDER_ARG] = gender;

            if (result.total == 1) { // askWithCarousel has min of two cards
                parameters[LAST_PRODUCTID_ARG] = result.records[0].id;
                app.ask(productCard(app, result.records[0], 'I found this for you'));
                return
            }
            app.setContext(OUT_CONTEXT, 1, parameters);
            app.askWithCarousel(inputPrompt, searchResultCarousel(app, result.records));
            
        }).catch((error) => {
            console.log("searchIntent error", error);
            app.tell(error);
        });
    }

    //not working
    function showSimilarIntent(app) {
        let query = app.getArgument('query');
        let gender = app.getArgument('gender');
        let productId = app.getContextArgument(OUT_CONTEXT, LAST_PRODUCTID_ARG);

        console.log("gender productId", query, gender, productId);

        apiHandler.search(query, gender).then((result) => {
            if ((typeof result.records === 'undefined') || (result.records.length == 0)) {
                if (typeof result.query_annotations !== 'undefined') {
                    app.ask(noResultCard(app));
                }
                app.ask(unknownQueryCard(app));
                return
            }
            let inputPrompt = app.buildRichResponse().addSimpleResponse('Here is what I found for you').addSuggestions(suggestionsFromAnnotations(result.records));
            console.log("inputPrompt", inputPrompt, result.records, productCard(app, result.records[0]), result.total);

            // answer
            console.log("arg", app.getContextArgument(OUT_CONTEXT, LAST_PRODUCTID_ARG));

            app.setContext(OUT_CONTEXT, 1, parameters);
            if (result.total == 1) { // askWithCarousel has min of two cards
                parameters[LAST_PRODUCTID_ARG] = result.records[0].id;
                app.ask(productCard(app, result.records[0], 'I found this for you'));
                return
            }
            app.askWithCarousel(inputPrompt, searchResultCarousel(app, result.records));
            
        }).catch((error) => {
            console.log("searchIntent error", error);
            app.tell(error);
        });
    }


    //define action map
    const actionMap = new Map();
    actionMap.set(OPTION_ACTION, optionIntent);
    actionMap.set(SUGGESTIONS_ACTION, suggestionsIntent);
    actionMap.set(SEARCH_ACTION, searchIntent);
    actionMap.set(SHOWSIMILAR_ACTION, showSimilarIntent);
    app.handleRequest(actionMap);

});

// Private methods

const mostFrequentObject = function (array) {
    var mF = [];
    var counts = {};
    var compare = 0;
    for (var i = 0, len = array.length; i < len; i++) {
        var word = array[i];

        if (counts[word] === undefined) {
            counts[word] = 1;
        } else {
            counts[word] = counts[word] + 1;
        }
        if (counts[word] > compare) {
            compare = counts[word];
            mF = array[i];
        }
    }
    return mF;
}

const suggestionsFromAnnotations = function (records) {
    let defaultSuggestions = ['Show me others'];
    var suggestions = [];
    var colors = [],
        fabrics = [],
        shapes = [];
    records.forEach(function (record) {
        if (typeof record.annotations === 'undefined') {
            return
        };
        if (typeof record.annotations.fabric !== 'undefined') {
            fabrics = fabrics.concat(record.annotations.fabric);
        };
        if (typeof record.annotations.color !== 'undefined') {
            colors = colors.concat(record.annotations.color);
        };
        if (typeof record.annotations.shapes !== 'undefined') {
            shapes = shapes.concat(record.annotations.shape);
        };
    });
    if ((colors.length == 0) &&  (shapes.length == 0) && (fabrics.length == 0)) {
        return defaultSuggestions;
    }
    suggestions.push(mostFrequentObject(colors));
    suggestions.push(mostFrequentObject(fabrics));
    suggestions.push(mostFrequentObject(shapes));
    return suggestions
}

// Templates

// Fresh Looks / Suggestions
const freshLooksList = function (app, records) {
    var buildOptionItems = [];
    records.forEach(function (record) {
        let key = record.id; // this key is used in optionIntent
        let imageUrl = record.items[0].source.image_url[0];
        let description = record.items[0].source.description;
        let title = record.items[0].source.name;
        buildOptionItems.push(app.buildOptionItem(key, [])
            .setTitle(title)
            .setDescription(description)
            .setImage(imageUrl, 'Image Placeholder'));
    });
    return app.buildList('Products').addItems(buildOptionItems)
}

const freshLooksCarousel = function (app, records) {
    var buildOptionItems = [];
    records.forEach(function (record) {
        let key = record.id; // this key is used in optionIntent
        let imageUrl = record.items[0].source.image_url[0];
        let description = record.items[0].source.description;
        let title = record.items[0].source.name;
        buildOptionItems.push(app.buildOptionItem(key, [])
            .setTitle(title)
            .setDescription(description)
            .setImage(imageUrl, 'Image Placeholder'));
    });
    return app.buildCarousel('Products').addItems(buildOptionItems)
}

// Search Result
const searchResultList = function (app, records) {
    var buildOptionItems = [];
    records.forEach(function (record) {
        let key = record.source.id; // this key is used in optionIntent
        buildOptionItems.push(app.buildOptionItem(key, [])
            .setTitle(record.source.name)
            .setDescription(record.source.description)
            .setImage(record.source.image_url[0], 'Image Placeholder'));
    });
    return app.buildList('Products').addItems(buildOptionItems)
}

const searchResultCarousel = function (app, records) {
    var buildOptionItems = [];
    records.forEach(function (record) {
        let key = record.source.id; // this key is used in optionIntent
        buildOptionItems.push(app.buildOptionItem(key, [])
            .setTitle(record.source.name)
            .setDescription(record.source.description)
            .setImage(record.source.image_url[0], 'Image Placeholder'));
    });
    return app.buildCarousel('Products').addItems(buildOptionItems)
}

// test response with mock data
const debugSERPCarousel = function (app, records) {
    console.log("first records", records[0]);
    let record = records[0];
    let key = record.source.id;
    
    return app.buildCarousel()
    // Add the first item to the carousel
    .addItems(app.buildOptionItem(key,[])
      .setTitle('Math & prime numbers')
      .setDescription('42 is an abundant number because the sum of its ' +
        'proper divisors 54 is greater…')
      .setImage('http://example.com/math_and_prime.jpg', 'Math & prime numbers'));
};

// Product details
const productCard = function (app, record, title = 'Nice choice!') {
    return app.buildRichResponse()
        // Create a basic card and add it to the rich response
        .addSimpleResponse(title)
        .addSuggestions(["Grey Sweater", "Jeans", "Ok, Goodbye"])
        .addBasicCard(app.buildBasicCard(record.source.description)
            .setTitle(record.source.name)
            .addButton('See more details', record.source.url)
            .setImage(record.source.image_url[0], 'Image placeholder text')
            .setImageDisplay('CROPPED')
        );
}

const unknownQueryCard = function (app) {
    let fallbackMessages = ["Sorry, I didn't get that.", "Sorry, could you say that again?"];
    let fallbackMessage = fallbackMessages[Math.floor(Math.random() * fallbackMessages.length)]; // random entry
    return app.buildRichResponse()
        // Create a basic card and add it to the rich response
        .addSimpleResponse(fallbackMessage)
        .addSuggestions(["Grey Sweater", "Jeans", "Ok, Goodbye"])
}

const noResultCard = function (app) {
    return app.buildRichResponse()
        // Create a basic card and add it to the rich response
        .addSimpleResponse("Sorry, we currently don't stock these. Maybe I can help you with something else?")
        .addSuggestions(["Grey Sweater", "Jeans", "Ok, Goodbye"])
}