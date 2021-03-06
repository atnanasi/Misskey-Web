$ = require 'jquery'
urldecorator = require '../../../common/urldecorator.js'
imageviewer = require './image-viewer.js'

module.exports = (post-type, $content) ->
	switch (post-type)
	| \status, \reply =>
		# Init url preview
		$content.find '> .text a:not(.mention):not(.hashtag)' .each ->
			$link = urldecorator $ @
			if USER_SETTINGS.enable-url-preview-in-post
				$.ajax "#{CONFIG.web-api-url}/web/url/analyze" {
					type: \get
					data:
						'url': $link.attr \href
					+cache}
				.done (html) ->
					$ html .append-to $content .hide!.fade-in 200ms
		# Images
		$content.find '> .photos > .photo' .each ->
			$image = $ @
			imageviewer $image
