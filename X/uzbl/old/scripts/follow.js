// Entire script borrowed heavily from the default follow.js with uzbl
// Modified to fit my idea of "proper" programming better, and for more functionality/flexibility
// Bear in mind I'm a physicist, not a programmer, so my "proper" programming is probably not so much that

// Globals - put in namespace to help with 'no globals' issues
var UzblFollowData = {
    // Data relevant to this functionality (defaults filled in)
    uzblHintDivId: "uzbl_link_hints",
    MAX_HINTS: 300,
    elemsHints: [],
    keypresses: "",
    numVis: 0,
    firstVis: -1,
    charset: "euhonadbk",
    followMode: "click",
    followable: "a, area, textarea, select, input:not([type=hidden]), button, *[onclick]",

    // And now for function declarations, yippee!

    // Get documents on page
    get_documents: function() {
        windows = function(w) {
            w = (typeof w == "undefined") ? window.top : w;
            var wins = [w];
            var frames = w.frames;
            for(var i = 0; i < frames.length; i++)
                wins = wins.concat(windows(frames[i]));
            return wins;
        }
        return windows().map(function (w) { return w.document; }).filter(function(d) { return d != null; });
    },

    // Calculate the element position on the page
    elemPosition: function(el) {
        // el.getBoundingClientRect is another way to do this, but when a link is
        // line-wrapped we want our hint at the left end of the link, not its
        // bounding rectangle
        var up     = el.offsetTop;
        var left   = el.offsetLeft;
        var width  = el.offsetWidth;
        var height = el.offsetHeight;

        while (el.offsetParent) {
            el = el.offsetParent;
            up += el.offsetTop;
            left += el.offsetLeft;
        }
        return [up, left, width, height];
    },

    // Clear all the Hints from the screen
    clearHints: function(doc) {
        var element = doc.getElementById(this.uzblHintDivId);
        while(element) {
            element.parentNode.removeChild(element);
            var element = doc.getElementById(this.uzblHintDivId);
        }
    },

    // Clear all internal data fields, call clearHints to clear all hints
    clear: function() {
        this.uzblHintDivId = "uzbl_link_hints";
        this.elemsHints = [];
        this.keypresses = "";
        this.numVis = 0;
        this.firstVis = -1;

        // Set default values for these variables
        this.charset = "euhonadkb";
        this.followMode = "click";
        this.followable  = "a, area, textarea, select, input:not([type=hidden]), button, *[onclick]";

        this.get_documents().forEach(this.clearHints, this);
    },

    // Checks for which hinted elements match the thus-far input string
    set_visible: function() {
        // Store the number of keys that have been pressed locally
        var keyNum = this.keypresses.length;

        // Reset the visible values
        this.numVis = 0;
        this.firstVis = -1;

        // Reverse search so we can get the "first visible" set properly
        for (var i = this.elemsHints.length-1; i >= 0; --i) {
            this.elemsHints[i]["visible"] = 0;

            // If it's supposed to be visible, set the "boolean", set the new display text, increment numVis, set firstVis
            if (this.elemsHints[i]["label"].slice(0, keyNum) == this.keypresses) {
                this.elemsHints[i]["visible"] = 1;
                ++this.numVis;
                this.firstVis = i;
            }
        }
    },

    // Follow the first visible link in the browser (could be the last link displaying)
    followFirstVisible: function() {
        // Check that there is a proper first visible element
        if (this.numVis < 1 || this.firstVis < 0)
            return "-error:No matching hints..." + this.numVis + this.firstVis;

        // Set the elem of interest
        var elem = this.elemsHints[this.firstVis]["elem"];
        var uri = elem.src || elem.href;

        // See if we're following a single link or want an array based on class
        if (this.followMode.indexOf("array") >= 0)
        {

        }
    },

    // Follow the first visible link in the browser (could be the last link displaying)
    followFirstVisible_orig: function() {
        // Check that there is a proper first visible element
        if (this.numVis < 1 || this.firstVis < 0)
            return "-error:No matching hints..." + this.numVis + this.firstVis;

        // Set the elem of interest
        var elem = this.elemsHints[this.firstVis]["elem"];
        var uri = elem.src || elem.href;

        // Code for checking things like link type
        // If the link needs clicked to follow
        else if (this.followMode.indexOf("click") >= 0 || this.followMode.indexOf("input") >= 0) {
            if(!elem) return "-error:No item to click...";

            //if (elem instanceof HTMLInputElement && uzbl.follow.inputTypeIsText(elem.type)) {
            if (elem instanceof HTMLInputElement || elem instanceof HTMLTextAreaElement || elem instanceof HTMLSelectElement) {
                elem.focus();
                if (typeof elem.select !== "undefined")
                    elem.select();
                return "-input:";
            }

            // simulate a mouseclick to activate the element
            var mouseEvent = document.createEvent("MouseEvent");
            mouseEvent.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
            elem.dispatchEvent(mouseEvent);
            return "-click:" + uri;
        }

        // Can add more special handling/functionality here

        // Otherwise return the uri of the element
        return "-uri:" + uri;
    },

    // Generate hint labels for each element in our list
    set_hintLabels: function() {
        var numElems = this.elemsHints.length;
        var numChars = this.charset.length;

        // Quick brute-force calculation of the hint length needed, should only get to 3 or so really
        var hintLen = 1;
        while (Math.pow(numChars, hintLen) < numElems)
            ++hintLen;

        // Now generate and save the hint labels - fastest variation in the first letter = more disimilar links close together
        for (var i = 0; i < numElems; ++i) {
            var label = "";
            var n = i;
            for (var j = 0; j < hintLen; ++j) {
                label = label + this.charset.charAt(n % numChars);
                n = Math.floor(n / numChars);
            }

            // Set the label and the position
            this.elemsHints[i]["label"] = label;
        }
    },

    // Calculate if an element is in the viewport
    elemInViewport: function(el) {
        var offset = this.elemPosition(el);
        var up     = offset[0];
        var left   = offset[1];
        var width  = offset[2];
        var height = offset[3];

        // If it's in the viewport box, return true, otherwise false
        return  up   < window.pageYOffset + window.innerHeight &&
            left < window.pageXOffset + window.innerWidth &&
            (up + height)  > window.pageYOffset &&
            (left + width) > window.pageXOffset;
    },

    // Query the relevant elements to use for display
    set_elemsHints: function() {
        var res = [];

        // Get all bits of the page that are "followable"
        this.get_documents().forEach(function (doc) {
            var set = doc.body.querySelectorAll(this.followable);
            // convert the NodeList to an Array
            set = Array.prototype.slice.call(set);
            res = res.concat(set);
        }, this);

        // Clear out our elemsHints parameter
        this.elemsHints = [];

        // Filter out to only the ones in the viewport, store the element, the top and the left position
        res.filter(this.elemInViewport, this).slice(0, this.MAX_HINTS).forEach(function(i) {
            var pos = this.elemPosition(i);
            this.elemsHints.push({"elem": i, "top": parseInt(pos[0]) + 2, "left": parseInt(pos[1]) + 2});
            }, this);
        //this.elemsHints.push(res.filter(elementInViewport).slice(0, this.MAX_HINTS).map(function(i)
        //    { return {"elem": i, "top": i.offsetTop, "left": i.offsetLeft}; }));

        // Populate the rest of the data fields we need
        this.set_hintLabels();
    },

    // Draw all hints for all elements passed.
    displayHints: function() {
        // we have to calculate element positions before we modify the DOM
        // otherwise the elementPosition call slows way down.
        var positions = [];
        for (var i = 0; i < this.elemsHints.length; ++i)
            positions.push(this.elemPosition(this.elemsHints[i]["elem"]));

        // Clear out (un-display) all the hints, then add a hint-div to each document to store the hints
        this.get_documents().forEach(function(doc) {
            // Clear the hints
            this.clearHints(doc);
            if (!doc.body) return;
            doc.hintdiv = doc.createElement("div");
            doc.hintdiv.id = this.uzblHintDivId;

            // I guess so we can have special treatement of certain types hints
            doc.hintdiv.className = this.followMode;
            doc.body.appendChild(doc.hintdiv);
        }, this);

        // Loop through, display the hints or don't
        for (var i = 0; i < this.elemsHints.length; ++i) {
            var elem = this.elemsHints[i];
            if (elem["visible"] == 1) {
                var el = elem["elem"];
                try {
                    // Get the top-level document to store this hint in
                    get_doc = function() {
                        if (el.tagName == "FRAME" || el.tagName == "IFRAME")
                            return el.contentDocument;

                        var docum = el;
                        while (docum.parentNode !== null)
                            docum = docum.parentNode;
                        return docum;
                    };

                    // Create the hint-span, append it to the hint-div for the document
                    var doc = get_doc();
                    var temp_hint = doc.createElement("div");
                    temp_hint.innerHTML = elem["label"].slice(this.keypresses.length);
                    temp_hint.style.position = "absolute";
                    temp_hint.style.top  = elem["top"]  + "px";
                    temp_hint.style.left = elem["left"] + "px";
                    temp_hint.style.fontSize = "11px";
                    temp_hint.style.backgroundColor = "#22AA44";
                    temp_hint.style.padding = "2px";
                    temp_hint.style.border = "1px solid #000000";
                    temp_hint.style.borderRadius = "6px";
                    temp_hint.style.zIndex = "10000";
                    doc.hintdiv.appendChild(temp_hint);
                } catch (err) {
                    // Unable to attach label -> shrug it off and continue
                }
            }
        }
    },

    // Update the characters the user has pressed
    updateChars: function(keys) {
        // Set keypresses, making sure to check keys for validity
        this.keypresses = (keys == "undefined") ? "" : keys;

        // Search over elemsHints and set how many visible we have, and which is the first visible one
        this.set_visible();

        // Display all the visible hints
        this.displayHints();

        // If we only have one visible option, use that
        if (this.numVis == 1) {
            var res = this.followFirstVisible();
            this.clear();
            return res;
        }
        else if (this.numVis < 1 && this.keypresses.length > 0 && this.elemsHints.length > 0)
            return "-badchar:" + this.updateChars(this.keypresses.slice(0,-1));
        else if (this.numVis < 1)
            return "-error:None visible"

        // Otherwise return the number of visible hints left
        return "-multmatch:" + this.numVis;
    },

    // Initial request for hints on the page
    requestFollow: function(cs, fm) {
        // Clear out object, set default values
        this.clear();

        // If the first argument exists, set it to the charset, second to followMode
        this.charset = (typeof cs == "undefined") ? this.charset : cs;
        this.followMode = (typeof fm == "undefined") ? this.followMode : fm;

        // Set the followable variable - the types of elements we want to hint at
        //focusable   = "a, area, textarea, select, input:not([type=hidden]), button, frame, iframe, applet, object";
        //desc        = "*[title], img[alt], applet[alt], area[alt], input[alt]";
        //image       = "img, input[type=image]";

        //Default hint types to display
        this.followable  = "a, area, textarea, select, input:not([type=hidden]), button, *[onclick]";

        // Pages to be opened in new windows only
        if(this.followMode.indexOf("new") >= 0)
            this.followable = "a, area, frame, iframe";
        // Input areas only
        else if(this.followMode.indexOf("input") >= 0)
            this.followable = "textarea, select, input:not([type=hidden])";

        // Set the types of hints we want to display
        this.set_elemsHints();

        // Return how many followable elements have been generated
        return "-success:" + this.elemsHints.length;
    }
};
