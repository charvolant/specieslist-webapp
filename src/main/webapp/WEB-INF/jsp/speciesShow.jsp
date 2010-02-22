<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
    <head>
        <meta name="pageName" content="species" />
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>ALA Biodiversity Information Explorer: ${extendedTaxonConcept.taxonConcept.nameString}</title>
        <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/static/fancybox/jquery.fancybox-1.2.6.css" media="screen" />
        <script type="text/javascript" src="${pageContext.request.contextPath}/static/fancybox/jquery.fancybox-1.2.6.pack.js"></script>
        <script type="text/javascript" src="${pageContext.request.contextPath}/static/js/jquery.easing.1.3.js"></script>
        <script type="text/javascript" src="${pageContext.request.contextPath}/static/js/jquery-galleryview-2.0/jquery.galleryview-2.0.js"></script>
        <script type="text/javascript" src="${pageContext.request.contextPath}/static/js/jquery-galleryview-2.0/jquery.timers-1.1.2.js"></script>
        <%--<script type="text/javascript" src="${pageContext.request.contextPath}/js/jquery.galleriffic.js"></script>--%>
        <!-- Combo-handled YUI CSS files: -->
        <link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/combo?2.8.0r4/build/tabview/assets/skins/sam/tabview.css">
        <!-- Combo-handled YUI JS files: -->
        <script type="text/javascript" src="http://yui.yahooapis.com/combo?2.8.0r4/build/yahoo-dom-event/yahoo-dom-event.js&2.8.0r4/build/element/element-min.js&2.8.0r4/build/tabview/tabview-min.js"></script>

        <script type="text/javascript">
            //var scientificNameId, scientificName;
            var solrServer = "${solrServerUrl}"; // 

            $(document).ready(function() {
                $("a.popup").fancybox({
                    'frameWidth' : 800,
                    'frameHeight' : 500,
                    'hideOnContentClick' : false
                });

                $("a.image").fancybox({
                    'imageScale' : true,
                    'hideOnContentClick' : false
                });

                $("a#lsid").fancybox({
                    'hideOnContentClick' : false,
                    'frameWidth' : 600,
                    'frameHeight' : 150
                });

                $("#view2").hide();
                $('a.hideShow').click(
                    function(e) {
                        e.preventDefault(); //Cancel the link behavior
                        var num = $(this).text();
                        var otherNum = (num == 1) ? 2 : 1;
                        $("#view"+otherNum).slideUp();
                        $("#view"+num).slideDown();
                    }
                );

                // Lookup portal for species info
                $.getJSON("http://data.ala.org.au/search/scientificNames/%22${extendedTaxonConcept.taxonName.nameComplete}%22/json?callback=?", function(data){
                    //alert("inspecting JSON data: " + data);
                    if (data.result.length > 0) {
                        var scientificNameId = data.result[0].scientificNameId;
                        var scientificName = data.result[0].scientificName;
                        var scientificNameUrl = "http://data.ala.org.au" + data.result[0].scientificNameUrl;
                        var occurrenceCount = data.result[0].occurrenceCount;
                        var occurrenceTableUrl = "http://data.ala.org.au/occurrences/searchWithTable.htm?c[0].s=20&c[0].p=0&c[0].o=" + scientificNameId;
                        // modify page DOM with values
                        $("a#portalLink").attr("href", scientificNameUrl);
                        //$("a#occurTableLink").attr("href", occurrenceTableUrl);
                        $("#occurrenceCount").html(occurrenceCount);
                        $("a#occurrenceTableLink").attr("href", occurrenceTableUrl);
                        $("#portalBookmark").fadeIn();
                        $("#portalInfo").slideDown();
                        loadMap(scientificName,scientificNameId);
                        //loadSpeciesRdf(scientificNameUrl);
                    } else {
                        // no records - check for other sections and if none then remove the "jumpt to" text
                        var tocListItems = $("div#toc ul").children();
                        if (tocListItems.length < 2) {
                            $("div#toc").hide();
                        }
                    }
                });

                // convert lsid link text to TC title via SOLR
                $("a.lsidLink").each(function() {
                    var link = $(this);
                    var lsid = link.text();
                    //link.text("foo");
                    var uri = encodeURIComponent(filterQuery(lsid));
                    var query = "q=dc.identifier:"+uri+" AND ContentModel:ala.TaxonConceptContentModel&wt=json&rows=1&indent=true&json.wrf=?"
                    $.getJSON(solrServer+"/select?"+query, function(data){
                        if (data.response.numFound > 0) {
                            var doc = data.response.docs[0];
                            var title = doc['dc.title'];
                            var rank = doc.Rank;
                            link.text(title+" ("+rank+")");
                            link.css("display","inline");
                        } else {
                            link.text("[name not known]");
                            link.attr("title", lsid);
                            link.css("display","inline");
                        }
                    });
                });

                // convert document id to info source name and link
                $("a.docId").each(function() {
                    var link = $(this);
                    var docId = link.text();
                    var uri = "${pageContext.request.contextPath}/species/document/"+docId+".json";
                    $.getJSON(uri, function(data) {
                        if (data.document.id > 0) {
                            if (link.attr("href") == "title") {
                                link.text(data.document.title);
                                link.attr("href", data.document.identifier);
                            } else if (link.attr("href") == "source") {
                                link.text(data.document.infoSourceName);
                                var uri2 = (data.document.infoSourceUri == null) ? "#" : data.document.infoSourceUri;
                                link.attr("href", uri2);
                            } else {
                                link.attr("title", data.document.identifier);
                                link.attr("alt", data.document.identifier);
                            }
                        }
                    });
                });

                $(".divider").hide();

                // Show/Hide long list
                //$(".showHide").siblings().append("<p><a href='#' class='showHideLink'>Show all</a></p>");
                $(".showHide").hide();
                $(".showHideLink").text("+ show more").css("font-size","12px");
                $(".showHideLink").toggle(function() {
                        $(".showHide").slideDown();
                        $(this).text("- show less");
                    }, function() {
                        $(".showHide").slideUp();
                        $(this).text("+ show more");
                    }
                 );

                 $('#photos').galleryView({
                    panel_width: 640,
                    panel_height: 480,
                    frame_width: 126,
                    frame_height: 100
                    <%--filmstrip_size: 4,
                    frame_width: 100,
                    frame_height: 100,
                    background_color: 'transparent',
                    nav_theme: 'dark',
                    border: 'none',
                    show_captions:true,
                    caption_text_color: 'black'--%>
                });

            });  // end document ready function

            /**
             * Escape special characters for SOLR query
             */
            function filterQuery(data) {
                data = data.replace(/\:/g, "\\:");
                data = data.replace(/\-/g, "\\-");
                return data;
            }

            //$("ul.yui-nav").hide();
            var tabView = new YAHOO.widget.TabView('tabs');

            // function to load YUI tabs
            function showTabs() {
                $("ul.yui-nav").show();
                $("#yui-box").addClass("yui-content");
                $(".divider").hide();
                tabView = new YAHOO.widget.TabView('tabs');
            }

            function hideTabs() {
                $("ul.yui-nav").hide();
                $("#harvestedInfo").show();
                $("#portalInfo").show();
                $("#images").show();
                $(".divider").show();
                $("#yui-box").removeClass("yui-content");
                tabView = null;
            }

        </script>
        <script type="text/javascript" src="${pageContext.request.contextPath}/static/js/ext-cdn-771.js"></script>
        <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/static/css/ext-all.css" />
        <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/static/css/ext-examples.css" />
        <script type="text/javascript" src="${pageContext.request.contextPath}/static/js/openlayers/OpenLayers.js"></script>
        <script type="text/javascript" src="${pageContext.request.contextPath}/static/js/GeoExt.js"></script>
        <script type="text/javascript">
            var map;

            /**
             * Initiate an OpenLayers Map
             */
            function loadMap(scientificName,scientificNameId) {
                var mapPanel;
                //Ext.onReady(function() {
                    var options = {
                        numZoomLevels: 12,
                        controls: []
                        // maxExtent: new OpenLayers.Bounds()
                    };
                    map = new OpenLayers.Map('mappanel', options);
                    var layer = new OpenLayers.Layer.WMS(
                        "Global Imagery",
                        "http://maps.opengeo.org/geowebcache/service/wms",
                        {layers: "bluemarble"},
                        {wrapDateLine: true}
                    );

                    var cellDensityLayerUrl = 'http://data.ala.org.au';
                    var entityName = '<span class="genera">' + scientificName + ' </span>';
                    var entityId = scientificNameId;
                    var entityType = 1; // species type

                    cellLayer = new OpenLayers.Layer.WMS(
                        entityName + " 1 degree cells",
                        "http://maps.ala.org.au/wms",  //cellDensityArray,
                        {layers: "ala:tabDensityLayer",
                        srs: 'EPSG:4326',
                        version: "1.0.0",
                        transparent: "true",
                        format: "image/png",
                        filter: "(<Filter><PropertyIsEqualTo><PropertyName>url</PropertyName><Literal><![CDATA["+cellDensityLayerUrl+"/mapping/simple/?id="+entityId+"&type="+entityType+"&unit=1]]></Literal></PropertyIsEqualTo></Filter>)"},
                        {opacity: "0.65", wrapDateLine: true, buffer: 0}
                    );

                    var statesLayer = new OpenLayers.Layer.WMS("Political States",
                        "http://maps.ala.org.au/wms",
                        {layers: "ala:as",
                        srs: 'EPSG:4326',
                        version: "1.0.0",
                        transparent: "true",
                        format: "image/png",
                        maxExtent: new OpenLayers.Bounds(112.91,-54.76,159.11,-10.06)},
                        {alpha: true}
                    );

                    map.addLayers([layer,cellLayer,statesLayer]);
                    map.addControl(new OpenLayers.Control.Navigation({zoomWheelEnabled: false}));
                    map.addControl(new OpenLayers.Control.PanZoom({zoomWorldIcon: false}));
                    map.setCenter(new OpenLayers.LonLat(133, -27), 4);

                    mapPanel = new GeoExt.MapPanel({
                        //title: "Species Density Map",
                        renderTo: "mappanel",
                        border: false,
                        heder: false,
                        height: 450,
                        width: 550,
                        map: map,
                        center: new OpenLayers.LonLat(133, -27),
                        zoom: 4
                    });
                //});
            }
        </script>
    </head>
    <body>
        <c:set var="taxonConceptTitle">
            <c:choose>
                <c:when test="${fn:length(taxonNames) > 0}">${taxonNames[0].nameComplete}</c:when>
                <c:otherwise>${taxonConcept.title}</c:otherwise>
            </c:choose>
        </c:set>
        <c:set var="taxonConceptRank">
            <c:choose>
                <c:when test="${taxonConcept != null}">${taxonConcept.rank}</c:when>
                <c:when test="${fn:length(extendedTaxonConcept.taxonName.rankLabel) > 0}">${extendedTaxonConcept.taxonName.rankLabel}</c:when>
                <c:otherwise>(rank not known)</c:otherwise>
            </c:choose>
        </c:set>
        <c:set var="sciNameFormatted">
            <c:choose>
                <%--<c:when test="${extendedTaxonConcept.taxonName.nameComplete != null}"><i>${extendedTaxonConcept.taxonName.nameComplete}</i></c:when>--%>
                <c:when test="${fn:endsWith(extendedTaxonConcept.taxonName.rankString,'gen')}"><i>${extendedTaxonConcept.taxonName.nameComplete}</i></c:when>
                <c:when test="${fn:endsWith(extendedTaxonConcept.taxonName.rankString,'sp')}"><i>${extendedTaxonConcept.taxonName.nameComplete}</i></c:when>
                <c:when test="${fn:endsWith(extendedTaxonConcept.taxonName.rankString,'sp')}"><i>${extendedTaxonConcept.taxonName.nameComplete}</i></c:when>
                <c:otherwise>${extendedTaxonConcept.taxonConcept.nameString}</c:otherwise>
            </c:choose>
        </c:set>
        <div id="speciesHeader">
            <c:if test="${fn:length(images) > 0}">
                <div id="speciesPhoto" class="cropBig">
                    <img src="${images[0].photoSourceUrl}" style="/*max-width:250px;max-height:280px;*/" width="300"  alt="species photo"/>
                </div>
            </c:if>
            <div id="speciesTitle">
                <h2>${fn:replace(extendedTaxonConcept.taxonConcept.nameString, extendedTaxonConcept.taxonName.nameComplete, sciNameFormatted)}</h2>
                <table class="noBorders" style="max-width:90%;margin:0;">
                    <tr>
                        <td class="propertyName">Classification:</td>
                        <td><fmt:message key="rank.${taxonConceptRank}" /></td>
                    </tr>
                    <c:if test="${fn:length(extendedTaxonConcept.taxonName.authorship) > 100}"><tr>
                        <td class="propertyName">Authorship:</td>
                        <td>${extendedTaxonConcept.taxonName.authorship}</td>
                    </tr></c:if>
                    <c:if test="${fn:length(extendedTaxonConcept.parentConcepts) > 0}"><tr>
                        <td class="propertyName">Parent <c:if test="${fn:length(extendedTaxonConcept.parentConcepts) > 1}">Taxa</c:if>
                            <c:if test="${fn:length(extendedTaxonConcept.parentConcepts) < 2}">Taxon</c:if>:
                        </td>
                        <td><c:forEach items="${extendedTaxonConcept.parentConcepts}" var="parent">
                                <a href="<c:url value='/species/${parent.guid}'/>">${parent.nameString}</a><br/>
                            </c:forEach>
                        </td>
                    </tr></c:if>
                    <c:if test="${fn:length(extendedTaxonConcept.childConcepts) > 0}"><tr>
                        <td class="propertyName">Child <c:if test="${fn:length(extendedTaxonConcept.childConcepts) > 1}">Taxa</c:if>
                            <c:if test="${fn:length(extendedTaxonConcept.childConcepts) < 2}">Taxon</c:if>:
                        </td>
                        <td><c:forEach items="${extendedTaxonConcept.childConcepts}" var="child">
                                <a href="<c:url value='/species/${child.guid}'/>">${child.nameString}</a><br/>
                            </c:forEach>
                        </td>
                    </tr></c:if>
                    <c:if test="${fn:length(extendedTaxonConcept.synonyms) > 0}"><tr>
                        <td class="propertyName">Synonyms:</td>
                        <td><div><c:forEach items="${extendedTaxonConcept.synonyms}" var="synonym" varStatus="status">
                                <%--<a href="<c:url value='/species/${synonym.guid}'/>">${synonym.nameString}</a><br/>--%>
                                ${synonym.nameString}<br/>
                                <c:if test="${status.count == 5}"></div><div class="showHide"></c:if>
                                <%--<c:if test="${status.last}"></c:if>--%>
                            </c:forEach>
                            </div>
                            <c:if test="${fn:length(extendedTaxonConcept.synonyms) > 5}"><div class="showHideDiv"><a href='#' class='showHideLink'></a></div></c:if>
                        </td>
                    </tr></c:if>
                    <c:if test="${fn:length(extendedTaxonConcept.commonNames) > 0}"><tr>
                        <td class="propertyName">Common Names:</td>
                        <td><div><c:forEach items="${extendedTaxonConcept.commonNames}" var="commonName" varStatus="status">
                                ${commonName.nameString}<br/>
                                <c:if test="${status.count == 5}"></div><div class="showHide"></c:if>
                            </c:forEach>
                            </div>
                        <c:if test="${fn:length(extendedTaxonConcept.commonNames) > 5}"><div class="showHideDiv"><a href='#' class='showHideLink'></a></div></c:if>
                        </td>
                    </tr></c:if>
                    <tr>
                        <td class="propertyName">Source:</td>
                        <td>
                            <%--<a href="<fmt:message key="source.${taxonConcept.source}.url" />" target="_blank"><fmt:message key="source.${taxonConcept.source}" /></a>--%>
                            ${extendedTaxonConcept.taxonConcept.infoSourceId}
                        </td>
                    </tr>
                </table>
                <div id="lsidText" style="display:none;">
                    <b><a href="http://lsids.sourceforge.net/" target="_blank">Life Science Identifier (LSID):</a></b>
                    <p style="margin: 10px 0;"><a href="http://lsid.tdwg.org/summary/${extendedTaxonConcept.taxonConcept.guid}" target="_blank">${extendedTaxonConcept.taxonConcept.guid}</a></p>
                    <p style="font-size: 12px;">LSIDs are persistent, location-independent,resource identifiers for uniquely naming biologically
                         significant resources including species names, concepts, occurrences, genes or proteins,
                         or data objects that encode information about them. To put it simply,
                        LSIDs are a way to identify and locate pieces of biological information on the web. </p>
                </div>
                <div id="LSID_icon"><a href="#lsidText" id="lsid"><img src="${pageContext.request.contextPath}/static/images/lsid.png"/></a></div>
            </div>
        </div>
        <div id="tabs" class="yui-navset" style="clear: both;">
            <ul class="yui-nav">
                <li><a href="#harvestedInfo"><em>Information from Other Sources</em></a></li>
                <li><a href="#portalInfo"><em>Distribution Map</em></a></li>
                <li class="selected"><a href="#images"><em>Images</em></a></li>
            </ul>
            <div id="yui-box" class="yui-content">
                <!-- Other taxon names (usually empty) -->
                <c:if test="${fn:length(taxonNames) > 1}"><a name="names">&nbsp;</a>
                    <h4 class="divider">Names</h4>
                    <table class="propertyTable">
                        <!-- Table headings. -->
                        <tr>
                            <th>Title</th>
                            <th>Scientific&nbsp;Name</th>
                            <th>Taxon&nbsp;Rank</th>
                            <th>Source</th>
                        </tr>
                        <!-- Dynamic table content. -->
                        <c:forEach items="${taxonNames}" var="tn">
                            <tr>
                                <td><a href="${tn.source}" target="_blank">${tn.title}</a></td>
                                <td>
                                    <c:choose>
                                        <c:when test="${fn:contains(tn.nameComplete, 'Species') || fn:contains(tn.nameComplete, 'Genus')}"><i>${tn.nameComplete}</i></c:when>
                                        <c:otherwise>${tn.nameComplete}</c:otherwise>
                                    </c:choose>
                                </td>
                                <td>
                                    <c:set var="rankMsg" value="${fn:replace(tn.rank, 'TaxonRank.', '')}"/>
                                    <fmt:message key="${rankMsg}" />
                                </td>
                                <td>${tn.source}</td>
                            </tr>
                        </c:forEach>
                    </table>
                </c:if>
                <!-- Harvested Info -->
                <div id="harvestedInfo">
                    <c:if test="${fn:length(orderedDocuments) > 0 && fn:length(orderedProperties) > 0}">
                        <h4 class="divider" style="">Information from Other Sources<a name="properties"></a></h4>
                        <%--<div style="float:right;width:20%;margin-top:-35px;text-align:right;">(Alternative View: <a href="#view1" class="hideShow">1</a> |
                            <a href="#view2" class="hideShow">2</a>)
                        </div>--%>
                        <div id="view2">
                            <c:forEach items="${orderedDocuments}" var="orderedDocument">
                                <div id="harvestedProperties">
                                    <p id="sourceTitle">${orderedDocument.infoSourceName} &ndash; <a href="${orderedDocument.sourceUrl}">${orderedDocument.sourceTitle} </a></p>
                                    <table class="propertyTable">
                                        <c:forEach var="categorisedProperties" items="${orderedDocument.categorisedProperties}">
                                            <c:if test="${categorisedProperties.category.name!='0Taxonomic' && categorisedProperties.category.name!='Media'}">
                                                <!--<p>${categorisedProperties.category.name}</p>-->
                                                <c:forEach var="entry" items="${categorisedProperties.propertyMap}">
                                                    <c:if test="${fn:length(entry.value) > 1}">
                                                        <tr><%--<s:set var="entryKey">${entry.key}</s:set>--%>
                                                        <td class="propertyName"><fmt:message key="${entry.key}"/></td>
                                                            <td>${entry.value}</td>
                                                        </tr>
                                                    </c:if>
                                                </c:forEach>
                                            </c:if>
                                        </c:forEach>
                                    </table>
                                </div>
                            </c:forEach>
                        </div>
                        <div id="view1">
                            <div id="harvestedProperties">
                                <table class="propertyTable">
                                    <tr>
                                        <th>Property</th>
                                        <th>Value</th>
                                        <th>Source</th>
                                    </tr>
                                    <c:forEach items="${orderedProperties}" var="orderedProperty">
                                        <tr class="${orderedProperty.category.name}">
                                            <td class="propertyName">
                                                <%--<s:set var="propertyName2">${orderedProperty.propertyName}</s:set>--%>
                                                <fmt:message key="${orderedProperty.propertyName}"/>
                                            </td>
                                            <td>
                                                 <c:choose>
                                                    <c:when test="${fn:startsWith(orderedProperty.propertyValue, 'http') && orderedProperty.propertyName == 'rdf.hasImageUrl'}">
                                                        <a href="${orderedProperty.propertyValue}" target="_blank" class="popup" title="${taxonConceptTitle}">${orderedProperty.propertyValue}</a>
                                                    </c:when>
                                                    <c:when test="${fn:startsWith(orderedProperty.propertyValue, 'http')}">
                                                        <a href="${orderedProperty.propertyValue}" target="_blank">${orderedProperty.propertyValue}</a>
                                                    </c:when>
                                                    <c:otherwise>
                                                        ${orderedProperty.propertyValue}
                                                    </c:otherwise>
                                                 </c:choose>
                                            </td>
                                            <td style="white-space: nowrap;">
                                                <c:choose>
                                                    <c:when test="${fn:length(orderedProperty.sources) > 1}">
                                                        <ul class="compact">
                                                        <c:forEach items="${orderedProperty.sources}" var="source">
                                                            <li><a href="${source.sourceUrl}" target="_blank">${source.infoSourceName}</a><br/></li>
                                                        </c:forEach>
                                                        </ul>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <a href="${orderedProperty.sources[0].sourceUrl}" target="_blank">${orderedProperty.sources[0].infoSourceName}</a>
                                                    </c:otherwise>
                                                </c:choose>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </table>
                            </div>
                        </div>
                    </c:if>
                </div>
                <!-- Map -->
                <div id="portalInfo">
                    <h4 class="divider">Distribution Map <a name="portal">&nbsp;</a></h4>
                    <div id="left">
                        <p>Species density layer generated from specimen & observation occurrence data</p>
                        <ul>
                            <li>Number of occurrences of ${sciNameFormatted}: <span id="occurrenceCount"></span></li>
                            <li><a href="#" id="occurrenceTableLink">View table of all occurrence records
                                    for ${sciNameFormatted}</a></li>
                            <li>Total number of records: <span id="occurrenceCount"></span></li>
                            <li>Breakdown by Regions</li>
                            <ul style="list-style-type: circle;">
                                <li>States:

                                </li>
                                <li>Local Government Areas:
                                </li>
                                <li>Biogeographical Regions:
                                </li>
                            </ul>
                        </ul>
                    </div>
                    <div id="mappanel"></div>
                    <div style="float:right;font-size:11px;width:550px;">
                        <table id="cellCountsLegend">
                            <tr>
                              <td style="background-color:#333; color:white; text-align:right;">Occurrences per cell:&nbsp;</td>
                              <td style="width:60px;background-color:#ffff00;">1&ndash;9</td>
                              <td style="width:60px;background-color:#ffcc00;">10&ndash;49</td>
                              <td style="width:60px;background-color:#ff9900;">50&ndash;99</td>
                              <td style="width:60px;background-color:#ff6600;">100&ndash;249</td>
                              <td style="width:60px;background-color:#ff3300;">250&ndash;499</td>
                              <td style="width:60px;background-color:#cc0000;">500+</td>
                            </tr>
                        </table>
                    </div>

                    <div style="clear: both;"></div>
                </div>

                <c:if test="${fn:length(extendedTaxonConcept.images) > 0}">
                    <div id="images">
                        <h4 class="divider">Images<a name="images">&nbsp;</a></h4>
                        <%--<div id="gallery" class="content">
                            <div id="controls" class="controls"></div>
                            <div class="slideshow-container">
                                    <div id="loading" class="loader"></div>
                                    <div id="slideshow" class="slideshow"></div>
                            </div>
                            <div id="caption" class="caption-container"></div>
                        </div>
                        <div id="thumbs" class="navigation">

                            <ul class="thumbs noscript">
                                <c:forEach items="${images}" var="image">
                                <li>
                                    <a class="thumb" name="optionalCustomIdentifier" href="${image.photoSourceUrl}" title="${image.title}">
                                        <img src="${image.photoSourceUrl}" alt="${image.title}" width="75" height="75"/>
                                    </a>
                                    <div class="caption">${image.description}</div>
                                </li>
                                </c:forEach>
                            </ul>
                        </div>
                        <div style="clear: both;"></div>--%>

                        <table class ="propertyTable" style="display: none">
                            <!-- Table headings. -->
                            <tr>
                                <th>Title</th>
                                <%--<th>Desciption</th>--%>
                                <th>Source</th>
                                <th>Thumbnail</th>
                            </tr>
                            <!-- Dynamic table content. -->
                            <c:forEach var="image" items="${extendedTaxonConcept.images}">
                                <tr>
                                    <td><a href="title" class="docId" target="_blank" title="${image.documentId}">${image.documentId}</a></td>
                                    <%--<td>${image.description}</td>--%>
                                    <td><a href="source" class="docId" target="_blank" title="${image.documentId}">${image.documentId}</a>
                                    </td>
                                    <td class="crop">
                                        <a href="http://localhost${fn:replace(image.repoLocation, "/data/bie", "/repository")}" class="image" target="_blank" title="<%--${image.title}--%>"><img src="http://localhost${fn:replace(image.repoLocation, "/data/bie", "/repository")}" width="120" /></a>
                                    </td>
                                </tr>
                            </c:forEach>
                        </table>
                        <div id="photos" class="galleryview">
                          <ul class="filmstrip">
                              <c:forEach var="image" items="${extendedTaxonConcept.images}">
                                   <li><a target="_blank" href="http://localhost${fn:replace(image.repoLocation, "/data/bie", "/repository")}" class="image" id="${image.documentId}"><img src="http://localhost${fn:replace(image.repoLocation, "/data/bie", "/repository")}" alt="" title="" /></a></li>
                              </c:forEach>
                          </ul>
                        </div>

                    </div>
                </c:if>
            </div>
        </div>

    </body>
</html>
