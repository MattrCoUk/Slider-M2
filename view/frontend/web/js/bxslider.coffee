# # #
# BxSlider v4.1.2 - Fully loaded, responsive content slider
# http://bxslider.com
#
# Copyright 2014, Steven Wanderski - http://stevenwanderski.com - http://bxcreative.com
# Written while drinking Belgian ales and listening to jazz
#
# Released under the MIT license - http://opensource.org/licenses/MIT
# # #

jQuery(document).ready ($) ->
   plugin = {}
   defaults =

# GENERAL
      mode:                      'vertical'
      slideSelector:             ''
      infiniteLoop:              true
      hideControlOnEnd:          false
      speed:                     700
      easing:                    null
      slideMargin:               0
      startSlide:                0
      randomStart:               false
      captions:                  false
      ticker:                    false
      tickerHover:               false
      adaptiveHeight:            false
      adaptiveHeightSpeed:       500
      video:                     false
      useCSS:                    true
      preloadImages:             'visible'
      responsive:                true
      slideZIndex:               50
      wrapperClass:              'bx-wrapper'

# TOUCH
      touchEnabled:              true
      swipeThreshold:            50
      oneToOneTouch:             true
      preventDefaultSwipeX:      true
      preventDefaultSwipeY:      false

# PAGER
      pager:                     true
      pagerType:                 'full'
      pagerShortSeparator:       ' / '
      pagerSelector:             null
      buildPager:                null
      pagerCustom:               null

# CONTROLS
      controls:                  true
      nextText:                  'Next'
      prevText:                  'Prev'
      nextSelector:              null
      prevSelector:              null
      autoControls:              false
      startText:                 'Start'
      stopText:                  'Stop'
      autoControlsCombine:       false
      autoControlsSelector:      null

# AUTO
      auto:                      false
      pause:                     8000
      autoStart:                 true
      autoDirection:             'next'
      autoHover:                 true
      autoDelay:                 0
      autoSlideForOnePage:       false

# CAROUSEL
      minSlides:                 1
      maxSlides:                 1
      moveSlides:                0
      slideWidth:                0
      
      
      onSliderLoad:              ->
      onSlideBefore:             ->
      onSlideAfter:              ->
      onSlideNext:               ->
      onSlidePrev:               ->
      onSliderResize:            ->
   
   $.fn.bxSlider = (options) ->
      if @length == 0
         return this
      # support mutltiple elements
      if @length > 1
         @each ->
            $(this).bxSlider options
            return
         return this
      # create a namespace to be used throughout the plugin
      slider = {}
      # set a reference to our slider element
      el = this
      plugin.el = this
      
      # # #
      # Makes slideshow responsive
      # # #
      
      # first get the original window dimens (thanks alot IE)
      windowWidth = $(window).width()
      windowHeight = $(window).height()
      
      # # #
      # ===================================================================================
      # = PRIVATE FUNCTIONS
      # ===================================================================================
      # # #
      
      # # #
      # Initializes namespace settings to be used throughout plugin
      # # #
      
      init = ->
# merge user-supplied options with the defaults
         slider.settings = $.extend({}, defaults, options)
         # parse slideWidth setting
         slider.settings.slideWidth = parseInt(slider.settings.slideWidth)
         # store the original children
         slider.children = el.children(slider.settings.slideSelector)
         # check if actual number of slides is less than minSlides / maxSlides
         if slider.children.length < slider.settings.minSlides
            slider.settings.minSlides = slider.children.length
         if slider.children.length < slider.settings.maxSlides
            slider.settings.maxSlides = slider.children.length
         # if random start, set the startSlide setting to random number
         if slider.settings.randomStart
            slider.settings.startSlide = Math.floor(Math.random() * slider.children.length)
         # store active slide information
         slider.active = index: slider.settings.startSlide
         # store if the slider is in carousel mode (displaying / moving multiple slides)
         slider.carousel = slider.settings.minSlides > 1 or slider.settings.maxSlides > 1
         # if carousel, force preloadImages = 'all'
         if slider.carousel
            slider.settings.preloadImages = 'all'
         # calculate the min / max width thresholds based on min / max number of slides
         # used to setup and update carousel slides dimensions
         slider.minThreshold = slider.settings.minSlides * slider.settings.slideWidth + (slider.settings.minSlides - 1) * slider.settings.slideMargin
         slider.maxThreshold = slider.settings.maxSlides * slider.settings.slideWidth + (slider.settings.maxSlides - 1) * slider.settings.slideMargin
         # store the current state of the slider (if currently animating, working is true)
         slider.working = false
         # initialize the controls object
         slider.controls = {}
         # initialize an auto interval
         slider.interval = null
         # determine which property to use for transitions
         slider.animProp = if slider.settings.mode == 'vertical' then 'top' else 'left'
         # determine if hardware acceleration can be used
         slider.usingCSS = slider.settings.useCSS and slider.settings.mode != 'fade' and do ->
# create our test div element
            div = document.createElement('div')
            # css transition properties
            props = [
               'WebkitPerspective'
               'MozPerspective'
               'OPerspective'
               'msPerspective'
            ]
            # test for each property
            for i of props
               if div.style[props[i]] != undefined
                  slider.cssPrefix = props[i].replace('Perspective', '').toLowerCase()
                  slider.animProp = '-' + slider.cssPrefix + '-transform'
                  return true
            false
         # if vertical mode always make maxSlides and minSlides equal
         if slider.settings.mode == 'vertical'
            slider.settings.maxSlides = slider.settings.minSlides
         # save original style data
         el.data 'origStyle', el.attr('style')
         el.children(slider.settings.slideSelector).each ->
            $(this).data 'origStyle', $(this).attr('style')
            return
         # perform all DOM / CSS modifications
         setup()
         return
      
      # # #
      # Performs all DOM and CSS modifications
      # # #
      
      setup = ->
         
         # wrap el in a wrapper
         el.wrap '<div class="' + slider.settings.wrapperClass + '"><div class="bx-viewport"></div></div>'
         
         # store a namspace reference to .bx-viewport
         slider.viewport = el.parent()
         
         # add a loading div to display while images are loading
         slider.loader = $('<div class="bx-loading" />')
         slider.viewport.prepend slider.loader
         # set el to a massive width, to hold any needed slides
         
         # also strip any margin and padding from el
         el.css
            width: if slider.settings.mode == 'horizontal' then slider.children.length * 100 + 215 + '%' else 'auto'
            position: 'relative'
         
         # if using CSS, add the easing property
         if slider.usingCSS and slider.settings.easing
            el.css '-' + slider.cssPrefix + '-transition-timing-function', slider.settings.easing
         
         # if not using CSS and no easing value was supplied, use the default JS animation easing (swing)
         else if !slider.settings.easing
            slider.settings.easing = 'swing'
         
         slidesShowing = getNumberSlidesShowing()
         
         # make modifications to the viewport (.bx-viewport)
         slider.viewport.css
            width: '100%'
            overflow: 'hidden'
            position: 'relative'
         
         slider.viewport.parent().css maxWidth: getViewportMaxWidth()
         
         # make modification to the wrapper (.bx-wrapper)
         if !slider.settings.pager
            slider.viewport.parent().css margin: '0 auto 0px'
         
         # apply css to all slider children
         slider.children.css
            'float': if slider.settings.mode == 'horizontal' then 'left' else 'none'
            listStyle: 'none'
            position: 'relative'
         
         # apply the calculated width after the float is applied to prevent scrollbar interference
         slider.children.css 'width', getSlideWidth()
         
         # if slideMargin is supplied, add the css
         if slider.settings.mode == 'horizontal' and slider.settings.slideMargin > 0
            slider.children.css 'marginRight', slider.settings.slideMargin
         if slider.settings.mode == 'vertical' and slider.settings.slideMargin > 0
            slider.children.css 'marginBottom', slider.settings.slideMargin
         
         # if "fade" mode, add positioning and z-index CSS
         if slider.settings.mode == 'fade'
            slider.children.css
               position: 'absolute'
               zIndex: 0
               display: 'none'
            # prepare the z-index on the showing element
            slider.children.eq(slider.settings.startSlide).css
               zIndex: slider.settings.slideZIndex
               display: 'block'
         
         # create an element to contain all slider controls (pager, start / stop, etc)
         slider.controls.el = $('<div class="bx-controls" />')
         
         # if captions are requested, add them
         if slider.settings.captions
            appendCaptions()
         
         # check if startSlide is last slide
         slider.active.last = slider.settings.startSlide == getPagerQty() - 1
         
         # if video is true, set up the fitVids plugin
         if slider.settings.video
            el.fitVids()
         
         # set the default preload selector (visible)
         preloadSelector = slider.children.eq(slider.settings.startSlide)
         if slider.settings.preloadImages == 'all'
            preloadSelector = slider.children
         
         # only check for control addition if not in "ticker" mode
         if !slider.settings.ticker
            # if pager is requested, add it
            if slider.settings.pager
               appendPager()
            # if controls are requested, add them
            if slider.settings.controls
               appendControls()
            # if auto is true, and auto controls are requested, add them
            if slider.settings.auto and slider.settings.autoControls
               appendControlsAuto()
            # if any control option is requested, add the controls wrapper
            if slider.settings.controls or slider.settings.autoControls or slider.settings.pager
               slider.viewport.after slider.controls.el
         
            # if ticker mode, do not allow a pager
         else
            slider.settings.pager = false
         
         # preload all images, then perform final DOM / CSS modifications that depend on images being loaded
         loadElements preloadSelector, start
         return
      
      loadElements = (selector, callback) ->
         total = selector.find('img, iframe').length
         if total == 0
            callback()
            return
         count = 0
         selector.find('img, iframe').each ->
            $(this).one('load', ->
               if ++count == total
                  callback()
               return
            ).each ->
               if @complete
                  $(this).load()
               return
            return
         return
      
      # # #
      # Start the slider
      # # #
      
      start = ->
         
         # if infinite loop, prepare additional slides
         if slider.settings.infiniteLoop and slider.settings.mode != 'fade' and !slider.settings.ticker
            slice = if slider.settings.mode == 'vertical' then slider.settings.minSlides else slider.settings.maxSlides
            sliceAppend = slider.children.slice(0, slice).clone().addClass('bx-clone')
            slicePrepend = slider.children.slice(-slice).clone().addClass('bx-clone')
            el.append(sliceAppend).prepend slicePrepend
         
         # remove the loading DOM element
         slider.loader.remove()
         
         # set the left / top position of "el"
         setSlidePosition()
         
         # if "vertical" mode, always use adaptiveHeight to prevent odd behavior
         #         if slider.settings.mode == 'vertical'
         #            slider.settings.adaptiveHeight = true
         
         # set the viewport height
         slider.viewport.height getViewportHeight()
         
         # make sure everything is positioned just right (same as a window resize)
         
         el.redrawSlider()
         
         # onSliderLoad callback
         slider.settings.onSliderLoad slider.active.index
         
         # slider has been fully initialized
         slider.initialized = true
         
         # bind the resize call to the window
         if slider.settings.responsive
            $(window).bind 'resize', resizeWindow
         
         # if auto is true and has more than 1 page, start the show
         if slider.settings.auto and slider.settings.autoStart and (getPagerQty() > 1 or slider.settings.autoSlideForOnePage)
            initAuto()
         
         # if ticker is true, start the ticker
         if slider.settings.ticker
            initTicker()
         
         # if pager is requested, make the appropriate pager link active
         if slider.settings.pager
            updatePagerActive slider.settings.startSlide
         # check for any updates to the controls (like hideControlOnEnd updates)
         if slider.settings.controls
            updateDirectionControls()
         # if touchEnabled is true, setup the touch events
         if slider.settings.touchEnabled and !slider.settings.ticker
            initTouch()
         return
      
      # # #
      # Returns the calculated height of the viewport, used to determine either adaptiveHeight or the maxHeight value
      # # #
      
      getViewportHeight = ->
         height = 0
         # first determine which children (slides) should be used in our height calculation
         children = $()
         # if mode is not "vertical" and adaptiveHeight is false, include all children
         if slider.settings.mode != 'vertical' and !slider.settings.adaptiveHeight
            children = slider.children
         else
# if not carousel, return the single active child
            if !slider.carousel
               children = slider.children.eq(slider.active.index)
# if carousel, return a slice of children
            else
# get the individual slide index
               currentIndex = if slider.settings.moveSlides == 1 then slider.active.index else slider.active.index * getMoveBy()
               # add the current slide to the children
               children = slider.children.eq(currentIndex)
               # cycle through the remaining "showing" slides
               i = 1
               while i <= slider.settings.maxSlides - 1
# if looped back to the start
                  if currentIndex + i >= slider.children.length
                     children = children.add(slider.children.eq(i - 1))
                  else
                     children = children.add(slider.children.eq(currentIndex + i))
                  i++
         # if "vertical" mode, calculate the sum of the heights of the children
         if slider.settings.mode == 'vertical'
            children.each (index) ->
               height += $(this).outerHeight()
               return
            # add user-supplied margins
            if slider.settings.slideMargin > 0
               height += slider.settings.slideMargin * (slider.settings.minSlides - 1)
# if not "vertical" mode, calculate the max height of the children
         else
            height = Math.max.apply(Math, children.map(->
               $(this).outerHeight false
            ).get())
         if slider.viewport.css('box-sizing') == 'border-box'
            height += parseFloat(slider.viewport.css('padding-top')) + parseFloat(slider.viewport.css('padding-bottom')) + parseFloat(slider.viewport.css('border-top-width')) + parseFloat(slider.viewport.css('border-bottom-width'))
         else if slider.viewport.css('box-sizing') == 'padding-box'
            height += parseFloat(slider.viewport.css('padding-top')) + parseFloat(slider.viewport.css('padding-bottom'))
         height
      
      # # #
      # Returns the calculated width to be used for the outer wrapper / viewport
      # # #
      
      getViewportMaxWidth = ->
         width = '100%'
         if slider.settings.slideWidth > 0
            if slider.settings.mode == 'horizontal'
               width = slider.settings.maxSlides * slider.settings.slideWidth + (slider.settings.maxSlides - 1) * slider.settings.slideMargin
            else
               width = slider.settings.slideWidth
         width
      
      # # #
      # Returns the calculated width to be applied to each slide
      # # #
      
      getSlideWidth = ->
# start with any user-supplied slide width
         newElWidth = slider.settings.slideWidth
         # get the current viewport width
         wrapWidth = slider.viewport.width()
         # if slide width was not supplied, or is larger than the viewport use the viewport width
         if slider.settings.slideWidth == 0 or slider.settings.slideWidth > wrapWidth and !slider.carousel or slider.settings.mode == 'vertical'
            newElWidth = wrapWidth
# if carousel, use the thresholds to determine the width
         else if slider.settings.maxSlides > 1 and slider.settings.mode == 'horizontal'
            if wrapWidth > slider.maxThreshold
# newElWidth = (wrapWidth - (slider.settings.slideMargin * (slider.settings.maxSlides - 1))) / slider.settings.maxSlides;
            else if wrapWidth < slider.minThreshold
               newElWidth = (wrapWidth - (slider.settings.slideMargin * (slider.settings.minSlides - 1))) / slider.settings.minSlides
         newElWidth
      
      # # #
      # Returns the number of slides currently visible in the viewport (includes partially visible slides)
      # # #
      
      getNumberSlidesShowing = ->
         slidesShowing = 1
         if slider.settings.mode == 'horizontal' and slider.settings.slideWidth > 0
# if viewport is smaller than minThreshold, return minSlides
            if slider.viewport.width() < slider.minThreshold
               slidesShowing = slider.settings.minSlides
# if viewport is larger than minThreshold, return maxSlides
            else if slider.viewport.width() > slider.maxThreshold
               slidesShowing = slider.settings.maxSlides
# if viewport is between min / max thresholds, divide viewport width by first child width
            else
               childWidth = slider.children.first().width() + slider.settings.slideMargin
               slidesShowing = Math.floor((slider.viewport.width() + slider.settings.slideMargin) / childWidth)
# if "vertical" mode, slides showing will always be minSlides
         else if slider.settings.mode == 'vertical'
            slidesShowing = slider.settings.minSlides
         slidesShowing
      
      # # #
      # Returns the number of pages (one full viewport of slides is one "page")
      # # #
      
      getPagerQty = ->
         pagerQty = 0
         # if moveSlides is specified by the user
         if slider.settings.moveSlides > 0
            if slider.settings.infiniteLoop
               pagerQty = Math.ceil(slider.children.length / getMoveBy())
            else
# use a while loop to determine pages
               breakPoint = 0
               counter = 0
               # when breakpoint goes above children length, counter is the number of pages
               while breakPoint < slider.children.length
                  ++pagerQty
                  breakPoint = counter + getNumberSlidesShowing()
                  counter += if slider.settings.moveSlides <= getNumberSlidesShowing() then slider.settings.moveSlides else getNumberSlidesShowing()
# if moveSlides is 0 (auto) divide children length by sides showing, then round up
         else
            pagerQty = Math.ceil(slider.children.length / getNumberSlidesShowing())
         pagerQty
      
      # # #
      # Returns the number of indivual slides by which to shift the slider
      # # #
      
      getMoveBy = ->
# if moveSlides was set by the user and moveSlides is less than number of slides showing
         if slider.settings.moveSlides > 0 and slider.settings.moveSlides <= getNumberSlidesShowing()
            return slider.settings.moveSlides
         # if moveSlides is 0 (auto)
         getNumberSlidesShowing()
      
      # # #
      # Sets the slider's (el) left or top position
      # # #
      
      setSlidePosition = ->
         `var position`
         `var position`
         # if last slide, not infinite loop, and number of children is larger than specified maxSlides
         if slider.children.length > slider.settings.maxSlides and slider.active.last and !slider.settings.infiniteLoop
            if slider.settings.mode == 'horizontal'
# get the last child's position
               lastChild = slider.children.last()
               position = lastChild.position()
               # set the left position
               setPositionProperty -(position.left - (slider.viewport.width() - lastChild.outerWidth())), 'reset', 0
            else if slider.settings.mode == 'vertical'
# get the last showing index's position
               lastShowingIndex = slider.children.length - (slider.settings.minSlides)
               position = slider.children.eq(lastShowingIndex).position()
               # set the top position
               setPositionProperty -position.top, 'reset', 0
# if not last slide
         else
# get the position of the first showing slide
            position = slider.children.eq(slider.active.index * getMoveBy()).position()
            # check for last slide
            if slider.active.index == getPagerQty() - 1
               slider.active.last = true
            # set the repective position
            if position != undefined
               if slider.settings.mode == 'horizontal'
                  setPositionProperty -position.left, 'reset', 0
               else if slider.settings.mode == 'vertical'
                  setPositionProperty -position.top, 'reset', 0
         return
      
      # # #
      # Sets the el's animating property position (which in turn will sometimes animate el).
      # If using CSS, sets the transform property. If not using CSS, sets the top / left property.
      #
      # @param value (int)
      #  - the animating property's value
      #
      # @param type (string) 'slider', 'reset', 'ticker'
      #  - the type of instance for which the function is being
      #
      # @param duration (int)
      #  - the amount of time (in ms) the transition should occupy
      #
      # @param params (array) optional
      #  - an optional parameter containing any variables that need to be passed in
      # # #
      
      setPositionProperty = (value, type, duration, params) ->
# use CSS transform
         if slider.usingCSS
# determine the translate3d value
            propValue = if slider.settings.mode == 'vertical' then 'translate3d(0, ' + value + 'px, 0)' else 'translate3d(' + value + 'px, 0, 0)'
            # add the CSS transition-duration
            el.css '-' + slider.cssPrefix + '-transition-duration', duration / 1000 + 's'
            if type == 'slide'
# set the property value
               el.css slider.animProp, propValue
               # bind a callback method - executes when CSS transition completes
               el.bind 'transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd', ->
# unbind the callback
                  el.unbind 'transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd'
                  updateAfterSlideTransition()
                  return
            else if type == 'reset'
               el.css slider.animProp, propValue
            else if type == 'ticker'
# make the transition use 'linear'
               el.css '-' + slider.cssPrefix + '-transition-timing-function', 'linear'
               el.css slider.animProp, propValue
               # bind a callback method - executes when CSS transition completes
               el.bind 'transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd', ->
# unbind the callback
                  el.unbind 'transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd'
                  # reset the position
                  setPositionProperty params['resetValue'], 'reset', 0
                  # start the loop again
                  tickerLoop()
                  return
# use JS animate
         else
            animateObj = {}
            animateObj[slider.animProp] = value
            if type == 'slide'
               el.animate animateObj, duration, slider.settings.easing, ->
                  updateAfterSlideTransition()
                  return
            else if type == 'reset'
               el.css slider.animProp, value
            else if type == 'ticker'
               el.animate animateObj, speed, 'linear', ->
                  setPositionProperty params['resetValue'], 'reset', 0
                  # run the recursive loop after animation
                  tickerLoop()
                  return
         return
      
      # # #
      # Populates the pager with proper amount of pages
      # # #
      
      populatePager = ->
         pagerHtml = ''
         pagerQty = getPagerQty()
         # loop through each pager item
         i = 0
         while i < pagerQty
            linkContent = ''
            # if a buildPager function is supplied, use it to get pager link value, else use index + 1
            if slider.settings.buildPager and $.isFunction(slider.settings.buildPager)
               linkContent = slider.settings.buildPager(i)
               slider.pagerEl.addClass 'bx-custom-pager'
            else
               linkContent = i + 1
               slider.pagerEl.addClass 'bx-default-pager'
            # var linkContent = slider.settings.buildPager && $.isFunction(slider.settings.buildPager) ? slider.settings.buildPager(i) : i + 1;
            # add the markup to the string
            pagerHtml += '<div class="bx-pager-item"><a href="" data-slide-index="' + i + '" class="bx-pager-link">' + linkContent + '</a></div>'
            i++
         # populate the pager element with pager links
         slider.pagerEl.html pagerHtml
         return
      
      # # #
      # Appends the pager to the controls element
      # # #
      
      appendPager = ->
         if !slider.settings.pagerCustom
# create the pager DOM element
            slider.pagerEl = $('<div class="bx-pager" />')
            # if a pager selector was supplied, populate it with the pager
            if slider.settings.pagerSelector
               $(slider.settings.pagerSelector).html slider.pagerEl
# if no pager selector was supplied, add it after the wrapper
            else
               slider.controls.el.addClass('bx-has-pager').append slider.pagerEl
            # populate the pager
            populatePager()
         else
            slider.pagerEl = $(slider.settings.pagerCustom)
         # assign the pager click binding
         slider.pagerEl.on 'click', 'a', clickPagerBind
         return
      
      # # #
      # Appends prev / next controls to the controls element
      # # #
      
      appendControls = ->
         slider.controls.next = $('<a class="bx-next" href="">' + slider.settings.nextText + '</a>')
         slider.controls.prev = $('<a class="bx-prev" href="">' + slider.settings.prevText + '</a>')
         # bind click actions to the controls
         slider.controls.next.bind 'click', clickNextBind
         slider.controls.prev.bind 'click', clickPrevBind
         # if nextSlector was supplied, populate it
         if slider.settings.nextSelector
            $(slider.settings.nextSelector).append slider.controls.next
         # if prevSlector was supplied, populate it
         if slider.settings.prevSelector
            $(slider.settings.prevSelector).append slider.controls.prev
         # if no custom selectors were supplied
         if !slider.settings.nextSelector and !slider.settings.prevSelector
# add the controls to the DOM
            slider.controls.directionEl = $('<div class="bx-controls-direction" />')
            # add the control elements to the directionEl
            slider.controls.directionEl.append(slider.controls.prev).append slider.controls.next
            # slider.viewport.append(slider.controls.directionEl);
            slider.controls.el.addClass('bx-has-controls-direction').append slider.controls.directionEl
         return
      
      # # #
      # Appends start / stop auto controls to the controls element
      # # #
      
      appendControlsAuto = ->
         slider.controls.start = $('<div class="bx-controls-auto-item"><a class="bx-start" href="">' + slider.settings.startText + '</a></div>')
         slider.controls.stop = $('<div class="bx-controls-auto-item"><a class="bx-stop" href="">' + slider.settings.stopText + '</a></div>')
         # add the controls to the DOM
         slider.controls.autoEl = $('<div class="bx-controls-auto" />')
         # bind click actions to the controls
         slider.controls.autoEl.on 'click', '.bx-start', clickStartBind
         slider.controls.autoEl.on 'click', '.bx-stop', clickStopBind
         # if autoControlsCombine, insert only the "start" control
         if slider.settings.autoControlsCombine
            slider.controls.autoEl.append slider.controls.start
# if autoControlsCombine is false, insert both controls
         else
            slider.controls.autoEl.append(slider.controls.start).append slider.controls.stop
         # if auto controls selector was supplied, populate it with the controls
         if slider.settings.autoControlsSelector
            $(slider.settings.autoControlsSelector).html slider.controls.autoEl
# if auto controls selector was not supplied, add it after the wrapper
         else
            slider.controls.el.addClass('bx-has-controls-auto').append slider.controls.autoEl
         # update the auto controls
         updateAutoControls if slider.settings.autoStart then 'stop' else 'start'
         return
      
      # # #
      # Appends image captions to the DOM
      # # #
      
      appendCaptions = ->
# cycle through each child
         slider.children.each (index) ->
# get the image title attribute
            title = $(this).find('img:first').attr('title')
            # append the caption
            if title != undefined and ('' + title).length
               $(this).append '<div class="bx-caption"><span>' + title + '</span></div>'
            return
         return
      
      # # #
      # Click next binding
      #
      # @param e (event)
      #  - DOM event object
      # # #
      
      clickNextBind = (e) ->
# if auto show is running, stop it
         if slider.settings.auto
            el.stopAuto()
         el.goToNextSlide()
         e.preventDefault()
         return
      
      # # #
      # Click prev binding
      #
      # @param e (event)
      #  - DOM event object
      # # #
      
      clickPrevBind = (e) ->
# if auto show is running, stop it
         if slider.settings.auto
            el.stopAuto()
         el.goToPrevSlide()
         e.preventDefault()
         return
      
      # # #
      # Click start binding
      #
      # @param e (event)
      #  - DOM event object
      # # #
      
      clickStartBind = (e) ->
         el.startAuto()
         e.preventDefault()
         return
      
      # # #
      # Click stop binding
      #
      # @param e (event)
      #  - DOM event object
      # # #
      
      clickStopBind = (e) ->
         el.stopAuto()
         e.preventDefault()
         return
      
      # # #
      # Click pager binding
      #
      # @param e (event)
      #  - DOM event object
      # # #
      
      clickPagerBind = (e) ->
# if auto show is running, stop it
         if slider.settings.auto
            el.stopAuto()
         pagerLink = $(e.currentTarget)
         if pagerLink.attr('data-slide-index') != undefined
            pagerIndex = parseInt(pagerLink.attr('data-slide-index'))
            # if clicked pager link is not active, continue with the goToSlide call
            if pagerIndex != slider.active.index
               el.goToSlide pagerIndex
            e.preventDefault()
         return
      
      # # #
      # Updates the pager links with an active class
      #
      # @param slideIndex (int)
      #  - index of slide to make active
      # # #
      
      updatePagerActive = (slideIndex) ->
# if "short" pager type
         len = slider.children.length
         # nb of children
         if slider.settings.pagerType == 'short'
            if slider.settings.maxSlides > 1
               len = Math.ceil(slider.children.length / slider.settings.maxSlides)
            slider.pagerEl.html slideIndex + 1 + slider.settings.pagerShortSeparator + len
            return
         # remove all pager active classes
         slider.pagerEl.find('a').removeClass 'active'
         # apply the active class for all pagers
         slider.pagerEl.each (i, el) ->
            $(el).find('a').eq(slideIndex).addClass 'active'
            return
         return
      
      # # #
      # Performs needed actions after a slide transition
      # # #
      
      updateAfterSlideTransition = ->
# if infinte loop is true
         if slider.settings.infiniteLoop
            position = ''
            # first slide
            if slider.active.index == 0
# set the new position
               position = slider.children.eq(0).position()
# carousel, last slide
            else if slider.active.index == getPagerQty() - 1 and slider.carousel
               position = slider.children.eq((getPagerQty() - 1) * getMoveBy()).position()
# last slide
            else if slider.active.index == slider.children.length - 1
               position = slider.children.eq(slider.children.length - 1).position()
            if position
               if slider.settings.mode == 'horizontal'
                  setPositionProperty -position.left, 'reset', 0
               else if slider.settings.mode == 'vertical'
                  setPositionProperty -position.top, 'reset', 0
         # declare that the transition is complete
         slider.working = false
         # onSlideAfter callback
         slider.settings.onSlideAfter slider.children.eq(slider.active.index), slider.oldIndex, slider.active.index
         return
      
      # # #
      # Updates the auto controls state (either active, or combined switch)
      #
      # @param state (string) "start", "stop"
      #  - the new state of the auto show
      # # #
      
      updateAutoControls = (state) ->
# if autoControlsCombine is true, replace the current control with the new state
         if slider.settings.autoControlsCombine
            slider.controls.autoEl.html slider.controls[state]
# if autoControlsCombine is false, apply the "active" class to the appropriate control
         else
            slider.controls.autoEl.find('a').removeClass 'active'
            slider.controls.autoEl.find('a:not(.bx-' + state + ')').addClass 'active'
         return
      
      # # #
      # Updates the direction controls (checks if either should be hidden)
      # # #
      
      updateDirectionControls = ->
         if getPagerQty() == 1
            slider.controls.prev.addClass 'disabled'
            slider.controls.next.addClass 'disabled'
         else if !slider.settings.infiniteLoop and slider.settings.hideControlOnEnd
# if first slide
            if slider.active.index == 0
               slider.controls.prev.addClass 'disabled'
               slider.controls.next.removeClass 'disabled'
# if last slide
            else if slider.active.index == getPagerQty() - 1
               slider.controls.next.addClass 'disabled'
               slider.controls.prev.removeClass 'disabled'
# if any slide in the middle
            else
               slider.controls.prev.removeClass 'disabled'
               slider.controls.next.removeClass 'disabled'
         return
      
      # # #
      # Initialzes the auto process
      # # #
      
      initAuto = ->
# if autoDelay was supplied, launch the auto show using a setTimeout() call
         if slider.settings.autoDelay > 0
            timeout = setTimeout(el.startAuto, slider.settings.autoDelay)
# if autoDelay was not supplied, start the auto show normally
         else
            el.startAuto()
         # if autoHover is requested
         if slider.settings.autoHover
# on el hover
            el.hover (->
# if the auto show is currently playing (has an active interval)
               if slider.interval
# stop the auto show and pass true agument which will prevent control update
                  el.stopAuto true
                  # create a new autoPaused value which will be used by the relative "mouseout" event
                  slider.autoPaused = true
               return
            ), ->
# if the autoPaused value was created be the prior "mouseover" event
               if slider.autoPaused
# start the auto show and pass true agument which will prevent control update
                  el.startAuto true
                  # reset the autoPaused value
                  slider.autoPaused = null
               return
         return
      
      # # #
      # Initialzes the ticker process
      # # #
      
      initTicker = ->
         startPosition = 0
         # if autoDirection is "next", append a clone of the entire slider
         if slider.settings.autoDirection == 'next'
            el.append slider.children.clone().addClass('bx-clone')
# if autoDirection is "prev", prepend a clone of the entire slider, and set the left position
         else
            el.prepend slider.children.clone().addClass('bx-clone')
            position = slider.children.first().position()
            startPosition = if slider.settings.mode == 'horizontal' then -position.left else -position.top
         setPositionProperty startPosition, 'reset', 0
         # do not allow controls in ticker mode
         slider.settings.pager = false
         slider.settings.controls = false
         slider.settings.autoControls = false
         # if autoHover is requested
         if slider.settings.tickerHover and !slider.usingCSS
# on el hover
            slider.viewport.hover (->
               el.stop()
               return
            ), ->
# calculate the total width of children (used to calculate the speed ratio)
               totalDimens = 0
               slider.children.each (index) ->
                  totalDimens += if slider.settings.mode == 'horizontal' then $(this).outerWidth(true) else $(this).outerHeight(true)
                  return
               # calculate the speed ratio (used to determine the new speed to finish the paused animation)
               ratio = slider.settings.speed / totalDimens
               # determine which property to use
               property = if slider.settings.mode == 'horizontal' then 'left' else 'top'
               # calculate the new speed
               newSpeed = ratio * (totalDimens - Math.abs(parseInt(el.css(property))))
               tickerLoop newSpeed
               return
         # start the ticker loop
         tickerLoop()
         return
      
      # # #
      # Runs a continuous loop, news ticker-style
      # # #
      
      tickerLoop = (resumeSpeed) ->
         speed = if resumeSpeed then resumeSpeed else slider.settings.speed
         position =
            left: 0
            top: 0
         reset =
            left: 0
            top: 0
         # if "next" animate left position to last child, then reset left to 0
         if slider.settings.autoDirection == 'next'
            position = el.find('.bx-clone').first().position()
# if "prev" animate left position to 0, then reset left to first non-clone child
         else
            reset = slider.children.first().position()
         animateProperty = if slider.settings.mode == 'horizontal' then -position.left else -position.top
         resetValue = if slider.settings.mode == 'horizontal' then -reset.left else -reset.top
         params = resetValue: resetValue
         setPositionProperty animateProperty, 'ticker', speed, params
         return
      
      # # #
      # Initializes touch events
      # # #
      
      initTouch = ->
# initialize object to contain all touch values
         slider.touch =
            start:
               x: 0
               y: 0
            end:
               x: 0
               y: 0
         slider.viewport.bind 'touchstart', onTouchStart
         return
      
      # # #
      # Event handler for "touchstart"
      #
      # @param e (event)
      #  - DOM event object
      # # #
      
      onTouchStart = (e) ->
         if slider.working
            e.preventDefault()
         else
# record the original position when touch starts
            slider.touch.originalPos = el.position()
            orig = e.originalEvent
            # record the starting touch x, y coordinates
            slider.touch.start.x = orig.changedTouches[0].pageX
            slider.touch.start.y = orig.changedTouches[0].pageY
            # bind a "touchmove" event to the viewport
            slider.viewport.bind 'touchmove', onTouchMove
            # bind a "touchend" event to the viewport
            slider.viewport.bind 'touchend', onTouchEnd
         return
      
      # # #
      # Event handler for "touchmove"
      #
      # @param e (event)
      #  - DOM event object
      # # #
      
      onTouchMove = (e) ->
         `var change`
         orig = e.originalEvent
         # if scrolling on y axis, do not prevent default
         xMovement = Math.abs(orig.changedTouches[0].pageX - (slider.touch.start.x))
         yMovement = Math.abs(orig.changedTouches[0].pageY - (slider.touch.start.y))
         # x axis swipe
         if xMovement * 3 > yMovement and slider.settings.preventDefaultSwipeX
            e.preventDefault()
# y axis swipe
         else if yMovement * 3 > xMovement and slider.settings.preventDefaultSwipeY
            e.preventDefault()
         if slider.settings.mode != 'fade' and slider.settings.oneToOneTouch
            value = 0
            # if horizontal, drag along x axis
            if slider.settings.mode == 'horizontal'
               change = orig.changedTouches[0].pageX - (slider.touch.start.x)
               value = slider.touch.originalPos.left + change
# if vertical, drag along y axis
            else
               change = orig.changedTouches[0].pageY - (slider.touch.start.y)
               value = slider.touch.originalPos.top + change
            setPositionProperty value, 'reset', 0
         return
      
      # # #
      # Event handler for "touchend"
      #
      # @param e (event)
      #  - DOM event object
      # # #
      
      onTouchEnd = (e) ->
         `var distance`
         slider.viewport.unbind 'touchmove', onTouchMove
         orig = e.originalEvent
         value = 0
         # record end x, y positions
         slider.touch.end.x = orig.changedTouches[0].pageX
         slider.touch.end.y = orig.changedTouches[0].pageY
         # if fade mode, check if absolute x distance clears the threshold
         if slider.settings.mode == 'fade'
            distance = Math.abs(slider.touch.start.x - (slider.touch.end.x))
            if distance >= slider.settings.swipeThreshold
               if slider.touch.start.x > slider.touch.end.x then el.goToNextSlide() else el.goToPrevSlide()
               el.stopAuto()
# not fade mode
         else
            distance = 0
            # calculate distance and el's animate property
            if slider.settings.mode == 'horizontal'
               distance = slider.touch.end.x - (slider.touch.start.x)
               value = slider.touch.originalPos.left
            else
               distance = slider.touch.end.y - (slider.touch.start.y)
               value = slider.touch.originalPos.top
            # if not infinite loop and first / last slide, do not attempt a slide transition
            if !slider.settings.infiniteLoop and (slider.active.index == 0 and distance > 0 or slider.active.last and distance < 0)
               setPositionProperty value, 'reset', 200
            else
# check if distance clears threshold
               if Math.abs(distance) >= slider.settings.swipeThreshold
                  if distance < 0 then el.goToNextSlide() else el.goToPrevSlide()
                  el.stopAuto()
               else
# el.animate(property, 200);
                  setPositionProperty value, 'reset', 200
         slider.viewport.unbind 'touchend', onTouchEnd
         return
      
      # # #
      # Window resize event callback
      # # #
      
      resizeWindow = (e) ->
# don't do anything if slider isn't initialized.
         if !slider.initialized
            return
         # get the new window dimens (again, thank you IE)
         windowWidthNew = $(window).width()
         windowHeightNew = $(window).height()
         # make sure that it is a true window resize
         # *we must check this because our dinosaur friend IE fires a window resize event when certain DOM elements
         # are resized. Can you just die already?*
         if windowWidth != windowWidthNew or windowHeight != windowHeightNew
# set the new window dimens
            windowWidth = windowWidthNew
            windowHeight = windowHeightNew
            # update all dynamic elements
            el.redrawSlider()
            # Call user resize handler
            slider.settings.onSliderResize.call el, slider.active.index
         return
      
      # # #
      # ===================================================================================
      # = PUBLIC FUNCTIONS
      # ===================================================================================
      # # #
      
      # # #
      # Performs slide transition to the specified slide
      #
      # @param slideIndex (int)
      #  - the destination slide's index (zero-based)
      #
      # @param direction (string)
      #  - INTERNAL USE ONLY - the direction of travel ("prev" / "next")
      # # #
      
      el.goToSlide = (slideIndex, direction) ->
         `var lastChild`
         # if plugin is currently in motion, ignore request
         if slider.working or slider.active.index == slideIndex
            return
         # declare that plugin is in motion
         slider.working = true
         # store the old index
         slider.oldIndex = slider.active.index
         # if slideIndex is less than zero, set active index to last child (this happens during infinite loop)
         if slideIndex < 0
            slider.active.index = getPagerQty() - 1
# if slideIndex is greater than children length, set active index to 0 (this happens during infinite loop)
         else if slideIndex >= getPagerQty()
            slider.active.index = 0
# set active index to requested slide
         else
            slider.active.index = slideIndex
         # onSlideBefore, onSlideNext, onSlidePrev callbacks
         slider.settings.onSlideBefore slider.children.eq(slider.active.index), slider.oldIndex, slider.active.index
         if direction == 'next'
            slider.settings.onSlideNext slider.children.eq(slider.active.index), slider.oldIndex, slider.active.index
         else if direction == 'prev'
            slider.settings.onSlidePrev slider.children.eq(slider.active.index), slider.oldIndex, slider.active.index
         # check if last slide
         slider.active.last = slider.active.index >= getPagerQty() - 1
         # update the pager with active class
         if slider.settings.pager
            updatePagerActive slider.active.index
         # // check for direction control update
         if slider.settings.controls
            updateDirectionControls()
         # if slider is set to mode: "fade"
         if slider.settings.mode == 'fade'
# if adaptiveHeight is true and next height is different from current height, animate to the new height
            if slider.settings.adaptiveHeight and slider.viewport.height() != getViewportHeight()
               slider.viewport.animate { height: getViewportHeight() }, slider.settings.adaptiveHeightSpeed
            # fade out the visible child and reset its z-index value
            slider.children.filter(':visible').fadeOut(slider.settings.speed).css zIndex: 0
            # fade in the newly requested slide
            slider.children.eq(slider.active.index).css('zIndex', slider.settings.slideZIndex + 1).fadeIn slider.settings.speed, ->
               $(this).css 'zIndex', slider.settings.slideZIndex
               updateAfterSlideTransition()
               return
# slider mode is not "fade"
         else
# if adaptiveHeight is true and next height is different from current height, animate to the new height
            if slider.settings.adaptiveHeight and slider.viewport.height() != getViewportHeight()
               slider.viewport.animate { height: getViewportHeight() }, slider.settings.adaptiveHeightSpeed
            moveBy = 0
            position =
               left: 0
               top: 0
            # if carousel and not infinite loop
            if !slider.settings.infiniteLoop and slider.carousel and slider.active.last
               if slider.settings.mode == 'horizontal'
# get the last child position
                  lastChild = slider.children.eq(slider.children.length - 1)
                  position = lastChild.position()
                  # calculate the position of the last slide
                  moveBy = slider.viewport.width() - lastChild.outerWidth()
               else
# get last showing index position
                  lastShowingIndex = slider.children.length - (slider.settings.minSlides)
                  position = slider.children.eq(lastShowingIndex).position()
# horizontal carousel, going previous while on first slide (infiniteLoop mode)
            else if slider.carousel and slider.active.last and direction == 'prev'
# get the last child position
               eq = if slider.settings.moveSlides == 1 then slider.settings.maxSlides - getMoveBy() else (getPagerQty() - 1) * getMoveBy() - (slider.children.length - (slider.settings.maxSlides))
               lastChild = el.children('.bx-clone').eq(eq)
               position = lastChild.position()
# if infinite loop and "Next" is clicked on the last slide
            else if direction == 'next' and slider.active.index == 0
# get the last clone position
               position = el.find('> .bx-clone').eq(slider.settings.maxSlides).position()
               slider.active.last = false
# normal non-zero requests
            else if slideIndex >= 0
               requestEl = slideIndex * getMoveBy()
               position = slider.children.eq(requestEl).position()
            
            # # # If the position doesn't exist
            # (e.g. if you destroy the slider on a next click),
            # it doesn't throw an error.
            # # #
            
            if 'undefined' != typeof position
               value = if slider.settings.mode == 'horizontal' then -(position.left - moveBy) else -position.top
               # plugin values to be animated
               setPositionProperty value, 'slide', slider.settings.speed
         return
      
      # # #
      # Transitions to the next slide in the show
      # # #
      
      el.goToNextSlide = ->
# if infiniteLoop is false and last page is showing, disregard call
         if !slider.settings.infiniteLoop and slider.active.last
            return
         pagerIndex = parseInt(slider.active.index) + 1
         el.goToSlide pagerIndex, 'next'
         return
      
      # # #
      # Transitions to the prev slide in the show
      # # #
      
      el.goToPrevSlide = ->
# if infiniteLoop is false and last page is showing, disregard call
         if !slider.settings.infiniteLoop and slider.active.index == 0
            return
         pagerIndex = parseInt(slider.active.index) - 1
         el.goToSlide pagerIndex, 'prev'
         return
      
      # # #
      # Starts the auto show
      #
      # @param preventControlUpdate (boolean)
      #  - if true, auto controls state will not be updated
      # # #
      
      el.startAuto = (preventControlUpdate) ->
# if an interval already exists, disregard call
         if slider.interval
            return
         # create an interval
         slider.interval = setInterval((->
            if slider.settings.autoDirection == 'next' then el.goToNextSlide() else el.goToPrevSlide()
            return
         ), slider.settings.pause)
         # if auto controls are displayed and preventControlUpdate is not true
         if slider.settings.autoControls and preventControlUpdate != true
            updateAutoControls 'stop'
         return
      
      # # #
      # Stops the auto show
      #
      # @param preventControlUpdate (boolean)
      #  - if true, auto controls state will not be updated
      # # #
      
      el.stopAuto = (preventControlUpdate) ->
# if no interval exists, disregard call
         if !slider.interval
            return
         # clear the interval
         clearInterval slider.interval
         slider.interval = null
         # if auto controls are displayed and preventControlUpdate is not true
         if slider.settings.autoControls and preventControlUpdate != true
            updateAutoControls 'start'
         return
      
      # # #
      # Returns current slide index (zero-based)
      # # #
      
      el.getCurrentSlide = ->
         slider.active.index
      
      # # #
      # Returns current slide element
      # # #
      
      el.getCurrentSlideElement = ->
         slider.children.eq slider.active.index
      
      # # #
      # Returns number of slides in show
      # # #
      
      el.getSlideCount = ->
         slider.children.length
      
      # # #
      # Update all dynamic slider elements
      # # #
      
      el.redrawSlider = ->
# resize all children in ratio to new screen size
         slider.children.add(el.find('.bx-clone')).width getSlideWidth()
         # adjust the height
         slider.viewport.css 'height', getViewportHeight()
         # update the slide position
         if !slider.settings.ticker
            setSlidePosition()
         # if active.last was true before the screen resize, we want
         # to keep it last no matter what screen size we end on
         if slider.active.last
            slider.active.index = getPagerQty() - 1
         # if the active index (page) no longer exists due to the resize, simply set the index as last
         if slider.active.index >= getPagerQty()
            slider.active.last = true
         # if a pager is being displayed and a custom pager is not being used, update it
         if slider.settings.pager and !slider.settings.pagerCustom
            populatePager()
            updatePagerActive slider.active.index
         return
      
      # # #
      # Destroy the current instance of the slider (revert everything back to original state)
      # # #
      
      el.destroySlider = ->
# don't do anything if slider has already been destroyed
         if !slider.initialized
            return
         slider.initialized = false
         $('.bx-clone', this).remove()
         slider.children.each ->
            if $(this).data('origStyle') != undefined then $(this).attr('style', $(this).data('origStyle')) else $(this).removeAttr('style')
            return
         if $(this).data('origStyle') != undefined then @attr('style', $(this).data('origStyle')) else $(this).removeAttr('style')
         $(this).unwrap().unwrap()
         if slider.controls.el
            slider.controls.el.remove()
         if slider.controls.next
            slider.controls.next.remove()
         if slider.controls.prev
            slider.controls.prev.remove()
         if slider.pagerEl and slider.settings.controls
            slider.pagerEl.remove()
         $('.bx-caption', this).remove()
         if slider.controls.autoEl
            slider.controls.autoEl.remove()
         clearInterval slider.interval
         if slider.settings.responsive
            $(window).unbind 'resize', resizeWindow
         return
      
      # # #
      # Reload the slider (revert all DOM changes, and re-initialize)
      # # #
      
      el.reloadSlider = (settings) ->
         if settings != undefined
            options = settings
         el.destroySlider()
         init()
         return
      
      init()
      # returns the current jQuery object
      this
   
   return