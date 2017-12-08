// Entire script borrowed heavily from the default follow.js with uzbl
// Modified to fit my idea of "proper" programming better, and for more functionality/flexibility
// Bear in mind I'm a physicist, not a programmer, so my "proper" programming is probably not so much that

// Globals - put in namespace to help with 'no globals' issues
var uzbl_follow_data = {
    // Data relevant to this functionality (defaults filled in)
    uzbl_hint_div_id: "uzbl_link_hints",
    elems_hints: [],
    curr_keys: "",
    char_set: "euhonadbk",
    follow_mode: "click",
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

    // Calculate if an element is in the viewport
    elem_in_viewport: function(el) {
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


    // Clear all the Hints from the screen
    clear_hints: function(doc) {
        var element = doc.getElementById(this.uzbl_hint_div_id);
        while(element) {
            element.parentNode.removeChild(element);
            var element = doc.getElementById(this.uzbl_hint_div_id);
        }
    },

    // Clear all internal data fields, call clear_hints to clear all hints
    clear: function() {
        this.uzbl_hint_div_id = "uzbl_link_hints";
        this.elems_hints = [];
        this.keypresses = "";
        this.num_vis = 0;
        this.first_vis = -1;

        // Set default values for these variables
        this.char_set = "euhonadkb";
        this.follow_mode = "click";
        this.followable  = "a, area, textarea, select, input:not([type=hidden]), button, *[onclick]";

        this.get_documents().forEach(this.clear_hints, this);
    },

    // Generate hint labels for each element in our list
    set_hint_labels: function() {
        var numElems = this.elems_hints.length;
        var numChars = this.char_set.length;

        // Quick brute-force calculation of the hint length needed, should only get to 3 or so really
        hint_len = 1;
        while (Math.pow(numChars, hint_len) < numElems)
            ++hint_len;

        // Now generate and save the hint labels - fastest variation in the first letter = more disimilar hints close together
        for (var i = 0; i < numElems; ++i) {
            var label = "";
            var n = i;
            for (var j = 0; j < hint_len; ++j) {
                label = label + this.char_set.charAt(n % numChars);
                n = Math.floor(n / numChars);
            }

            // Set the label and the position
            this.elems_hints[i]["label"] = label;
        }
    },

    // Query the relevant elements to use for display
    set_elems_hints: function() {
        var res = [];

        // Get all bits of the page that are "followable"
        this.get_documents().forEach(function (doc) {
            var set = doc.body.querySelectorAll(this.followable);
            // convert the NodeList to an Array
            set = Array.prototype.slice.call(set);
            res = res.concat(set);
        }, this);

        // Clear out our elems_hints parameter
        this.elems_hints = [];

        // Create our array of followable 'things' and their positions
        res.forEach(function(i) {
            var pos = this.elemPosition(i);
            this.elems_hints.push({"elem": i, "top": parseInt(pos[0]), "left": parseInt(pos[1]), "visible": 1, "class": this.className});
            }, this);

        // Populate the rest of the data fields we need
        this.set_hint_labels();
    },


    // Draw all hints for all elements passed.
    display_hints: function() {

        // Clear out all the hints, then add a hint-div to each document to store the hints
        this.get_documents().forEach(function(doc) {
            // Clear the hints
            this.clear_hints(doc);
            if (!doc.body) return;
            doc.hintdiv = doc.createElement("div");
            doc.hintdiv.id = this.uzbl_hint_div_id;

            // I guess so we can have special treatement of certain types hints
            doc.hintdiv.className = this.follow_mode;
            doc.body.appendChild(doc.hintdiv);
        }, this);

        // Loop through, display the hints or don't
        for (var i = 0; i < this.elems_hints.length; ++i) {
            var elem = this.elems_hints[i];
            if (elem["visible"] == 1) {
                var el = elem["elem"];
                try {
                    get_doc  = function(e_l) {
                        // Get the top-level document to store this hint in
                        if (e_l.tagName == "FRAME" || e_l.tagName == "IFRAME")
                            return e_l.contentDocument;

                        var docum = e_l;
                        while (docum.parentNode !== null)
                            docum = docum.parentNode;
                        return docum;
                    };

                    // Create the hint-span, append it to the hint-div for the document
                    var doc = this.get_doc(el);
                    var temp_hint = doc.createElement("div");
                    temp_hint.innerHTML = elem["label"].slice(this.keypresses.length);
                    temp_hint.style.position = "absolute";
                    temp_hint.style.top  = (parseInt(elem["top"]) + 2)  + "px";
                    temp_hint.style.left = (parseInt(elem["left"]) + 2) + "px";
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

    // Function to follow a certain element
    follow_elem: function(elem_num) {
        // Set the elem of interest
        var elem = this.elemsHints[elem_num]["elem"];
        var uri = elem.src || elem.href;

        // Code for checking things like link type
        // If the link needs clicked to follow
        if (this.followMode == "click") {
            // Simulate a mouseclick to activate the element
            var mouseEvent = document.createEvent("MouseEvent");
            mouseEvent.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
            elem.dispatchEvent(mouseEvent);
            return;
        }

        // Otherwise return the uri of the element
        if (this.follow_mode == 'uri')
        {
            return this.elems_hints[elem_num]["uri"];
        }

        // And if we have an array of uris to return
        if (this.follow_mode == 'class')
        {
            return_string = "";
            for (var i = 0; i < this.elems_hints.length; ++i) {
                if (this.elems_hints[i]["class"] == this.elems_hints[elem_num]["class"])
                {
                    return_string += this.elems_hints[i]["uri"] + " ";
                }
            }
            return return_string;
        }

        // Errored out!
        return -1;
    },

    // Function to update the characters pressed field
    update_chars: function(keys) {
        // Go through and set truth values on each hint
        // Count remaining hints while we're at it
        num_vis = 0;
        vis_elem = -1;
        for (var i = 0; i < this.elems_hints.length; ++i) {
            this.elems_hints[i]["visible"] = true;
            if(this.elems_hints[i]["label"].indexOf(keys) != 0) {
                this.elems_hints[i]["visible"] = false;
                vis_elem = i;
                ++num_vis;
            }
        }

        // Check if we only have one visible link available
        if (num_vis == 1) {
            this.clear();
            return this.follow_elem(vis_elem);
        }
        return -1;
    },

    // Initial request for hints on the page
    init_follow: function(cs, fm) {
        // Clear out object, set default values
        this.clear();

        // If the first argument exists, set it to the char_set, second to follow_mode
        this.char_set = (typeof cs == "undefined") ? this.char_set : cs;
        this.follow_mode = (typeof fm == "undefined") ? this.follow_mode : fm;

        //Default hint types to display
        this.followable  = "a, area, textarea, select, input:not([type=hidden]), button, *[onclick]";

        // Set the types of hints we want to display
        this.set_elems_hints();

        // Display all our hints
        this.display_hints();
    }
};
