$ = require 'jquery'
require 'jquery.transit'
moment = require 'moment'
Sortable = require 'Sortable'
require 'blockadblock'

require './main.js'
require './kronos.js'
Tab = require './lib/tab.js'
WavesEffect = require './lib/waves-effect.js'
Album = require './album.js'
sncompleter = require './sncompleter.js'
show-modal-window = require './modal-window.js'
show-modal-dialog = require './modal-dialog.js'
ui-window = require './window.js'
init-i-settings-dialog = require './i-settings.js'

album = new Album

if block-ad-block == undefined
	ad-block-detected!
else
	block-ad-block.on-detected ad-block-detected

function ad-block-detected
	$modal-ok = $ '<button>了解</button>'
	dialog-close = show-modal-dialog do
		$ '<p><i class="fa fa-exclamation-triangle"></i>広告ブロッカーが有効です</p>'
		'<strong>Misskeyは広告を掲載していません</strong>が、広告ブロッカーが有効だと一部の機能が利用できない場合があります(ユーザーのフォローが出来ないなど)。
		Misskeyを快適にご利用いただくためには、広告ブロッカーを無効にしてください。'
		[$modal-ok]
	$modal-ok.click -> dialog-close!

window.display-message = (message) ->
	$message = $ '<p class="ui-message">' .text message
	$ \body .prepend $message
	$message.transition {
		opacity: \1
		perspective: \1024
		rotate-x: \0
	} 200ms \ease
	set-timeout ->
		$message.transition {
			opacity: \0
			perspective: \1024
			rotate-x: \90
		} 200ms \ease ->
			$message.remove!
	, 5000ms

window.upload-file = (file, uploading, success, failed) ->
	data = new FormData!
		..append \file file
	$.ajax "#{config.web-api-url}/web/sites/desktop/album/upload" {
		+async
		-process-data
		-content-type
		data: data
		data-type: \text
		xhr: ->
			XHR = $.ajax-settings.xhr!
			if XHR.upload
				XHR.upload.add-event-listener \progress (e) ->
					percentage = Math.floor (parse-int e.loaded / e.total * 10000) / 100
					uploading e.total, e.loaded, percentage
				, false
			XHR
	}
	.done (html) ->
		success html
	.fail (data) ->
		failed!

window.open-select-album-file-dialog = (cb) ->
	album.choose-file cb

function update-header-statuses
	/*
	$.ajax "#{config.web-api-url}/web/get-header-statuses" {
		data-type: \json}
	.done (result) ->
		unread-notifications-count = result.unread-notifications-count
		unread-talk-messages-count = result.unread-talk-messages-count

		if $ '#misskey-main-header .notifications .unread-count' .0
			$ '#misskey-main-header .notifications .unread-count' .remove!
		if unread-notifications-count != 0
			$ '#misskey-main-header .notifications .dropdown .dropdown-header p' .append do
				$ '<span class="unread-count">' .text unread-notifications-count

		if $ '#misskey-main-header > .main .mainContentsContainer .left nav .mainNav ul .talk a .unreadCount' .0
			$ '#misskey-main-header > .main .mainContentsContainer .left nav .mainNav ul .talk a .unreadCount' .remove!
		if unread-talk-messages-count != 0
			$ '#misskey-main-header > .main .mainContentsContainer .left nav .mainNav ul .talk a' .append do
				$ '<span class="unreadCount">' .text unread-talk-messages-count
	.fail ->
	*/

function update-header-clock
	s = (new Date!).get-seconds!
	m = (new Date!).get-minutes!
	h = (new Date!).get-hours!
	yyyymmdd = moment!.format 'YYYY/MM/DD'
	yyyymmdd = "<span class='yyyymmdd'>#yyyymmdd</span>"
	hhmm = moment!.format 'HH:mm'
	if s % 2 == 0
		hhmm .= replace \: '<span style=\'visibility:visible\'>:</span>'
	else
		hhmm .= replace \: '<span style=\'visibility:hidden\'>:</span>'
	clock = $ '#misskey-main-header .time .now'
	clock.html "#yyyymmdd<br>#hhmm"

	# DRAW CLOCK
	vec2 = (x, y) ->
		@.x = x
		@.y = y

	canvas = document.get-element-by-id \misskey-main-clock-canvas
	ctx = canvas.get-context \2d
	canv-w = canvas.width
	canv-h = canvas.height
	ctx.clear-rect 0, 0, canv-w, canv-h

	# 背景
	center = (Math.min (canv-w / 2), (canv-h / 2))
	line-start = center * 0.90
	line-end-short = center * 0.87
	line-end-long = center * 0.84
	for i from 0 to 59 by 1
		angle = Math.PI * i / 30
		uv = new vec2 (Math.sin angle), (-Math.cos angle)
		ctx.begin-path!
		ctx.line-width = 1
		ctx.move-to do
			(canv-w / 2) + uv.x * line-start
			(canv-h / 2) + uv.y * line-start
		if i % 5 == 0
			ctx.stroke-style = 'rgba(255, 255, 255, 0.2)'
			ctx.line-to do
				(canv-w / 2) + uv.x * line-end-long
				(canv-h / 2) + uv.y * line-end-long
		else
			ctx.stroke-style = 'rgba(255, 255, 255, 0.1)'
			ctx.line-to do
				(canv-w / 2) + uv.x * line-end-short
				(canv-h / 2) + uv.y * line-end-short
		ctx.stroke!

	# 分
	angle = Math.PI * (m + s / 60) / 30
	length = (Math.min canv-w, canv-h) / 2.6
	uv = new vec2 (Math.sin angle), (-Math.cos angle)
	ctx.begin-path!
	ctx.stroke-style = \#ffffff
	ctx.line-width = 2
	ctx.move-to do
		(canv-w / 2) - uv.x * length / 5
		(canv-h / 2) - uv.y * length / 5
	ctx.line-to do
		(canv-w / 2) + uv.x * length
		(canv-h / 2) + uv.y * length
	ctx.stroke!

	# 時
	angle = Math.PI * (h % 12 + m / 60) / 6
	length = (Math.min canv-w, canv-h) / 4
	uv = new vec2 (Math.sin angle), (-Math.cos angle)
	ctx.begin-path!
	#ctx.stroke-style = \#ffffff
	ctx.stroke-style = config.themeColor
	ctx.line-width = 2
	ctx.move-to do
		(canv-w / 2) - uv.x * length / 5
		(canv-h / 2) - uv.y * length / 5
	ctx.line-to do
		(canv-w / 2) + uv.x * length
		(canv-h / 2) + uv.y * length
	ctx.stroke!

	# 秒
	angle = Math.PI * s / 30
	length = (Math.min canv-w, canv-h) / 2.6
	uv = new vec2 (Math.sin angle), (-Math.cos angle)
	ctx.begin-path!
	ctx.stroke-style = 'rgba(255, 255, 255, 0.5)'
	ctx.line-width = 1
	ctx.move-to do
		(canv-w / 2) - uv.x * length / 5
		(canv-h / 2) - uv.y * length / 5
	ctx.line-to do
		(canv-w / 2) + uv.x * length
		(canv-h / 2) + uv.y * length
	ctx.stroke!

class PostForm
	->
		THIS = @

		THIS.photoPostForm = new PhotoPostForm THIS
		THIS.statusPostForm = new StatusPostForm THIS

		THIS.tab = Tab do
			$ '#misskey-post-form-tabs'
			$ '#misskey-post-form-tab-pages'
			(id) ->
				switch (id)
				| \status => THIS.statusPostForm.focus!
				| \photo => THIS.photoPostForm.focus!

		$ \#misskey-post-button .click ->
			THIS.open!
		$ \#misskey-post-form .click (e) ->
			e.stop-propagation!
		$ \#misskey-post-form-container .click ->
			THIS.close!
		$ \#misskey-post-form .find \.close-button .click ->
			THIS.close!

	open: ->
		THIS = @
		$ \#misskey-post-form-back .css \display \block
		$ \#misskey-post-form-back .animate {
			opacity: 1
		} 100ms \linear
		$ \#misskey-post-form-container .css \display \block
		$ \#misskey-post-form .stop!
		$ \#misskey-post-form .css \transform 'scale(1.2)'
		$ \#misskey-post-form .transition {
			opacity: \1
			scale: \1
		} 1000ms 'cubic-bezier(0, 1, 0, 1)'
		$ \#misskey-post-form-tabs .find \li .each (i) ->
			$tab = $ @
			$tab.find \i .css \transition \none
			$tab.find \i .css {
				top: \-16px
				opacity: 0
			}
			set-timeout ->
				$tab.find \i .css \transition 'top 0.3s ease-out, opacity 0.3s ease-out'
				$tab.find \i .css {
					top: \0px
					opacity: 1
				}
				set-timeout ->
					$tab.find \i .css {
						transition: ''
						top: ''
					}
				, 300ms
			, i * 50
		THIS.statusPostForm.focus!

	close: ->
		$ \#misskey-post-form-back .animate {
			opacity: 0
		} 100ms \linear -> $ \#misskey-post-form-back .css \display \none
		$ \#misskey-post-form .stop!
		$ \#misskey-post-form .transition {
			opacity: \0
			scale: \0.8
		} 1000ms 'cubic-bezier(0, 1, 0, 1)' ->
			if ($ \#misskey-post-form .css \opacity) === '0'
				$ \#misskey-post-form-container .css \display \none

	upload-file: (file, $form, complete) ->
		name = if file.has-own-property \name then file.name else 'untitled'
		$info = $ "<li><p class='name'>#{name}</p><progress></progress></li>"
		$progress-bar = $info.find \progress
		$form.find '> .uploads' .append $info
		window.upload-file do
			file
			(total, uploaded, percentage) ->
				if percentage == 100
					$progress-bar
						..remove-attr \value
						..remove-attr \max
				else
					$progress-bar
						..attr \max total
						..attr \value uploaded
			(html) ->
				$info.remove!
				complete html
			->
				$info.remove!

class StatusPostForm
	(postForm) ->
		THIS = @
		THIS.postForm = postForm

		sncompleter $ '#misskey-post-form-status-tab-page textarea'

		$ '#misskey-post-form-status-tab-page textarea' .bind \input ->
			$ \#misskey-post-form .find \.submit-button .attr \disabled off

		$ '#misskey-post-form-status-tab-page textarea' .keypress (e) ->
			if (e.char-code == 10 || e.char-code == 13) && e.ctrl-key
				THIS.submit!

		$ '#misskey-post-form-status-tab-page textarea' .on \paste (event) ->
			items = (event.clipboard-data || event.original-event.clipboard-data).items
			for i from 0 to items.length - 1
				item = items[i]
				if item.kind == \file && item.type.index-of \image != -1
					file = item.get-as-file!
					THIS.postForm.photoPostForm.focus!
					THIS.postForm.photoPostForm.upload-new-file file

		$ \#misskey-post-form-status-tab-page .find '.image-attacher input[name=image]' .change ->
			$input = $ @
			$ \#misskey-post-form .find '.image-preview-container' .css \display \block
			$ \#misskey-post-form .find \.submit-button .attr \disabled off
			file = $input.prop \files .0
			if file.type.match 'image.*'
				reader = new FileReader!
					..onload = ->
						$img = $ '<img>' .attr \src reader.result
						$ \#misskey-post-form .find '.image-preview' .find 'img' .remove!
						$ \#misskey-post-form .find '.image-preview' .append $img
					..readAsDataURL file

		$ \#misskey-post-form-status-tab-page .submit (event) ->
			event.prevent-default!
			THIS.submit!

	submit: ->
		THIS = @

		$form = $ \#misskey-post-form-status-tab-page
		$submit-button = $form.find '[type=submit]'

		$submit-button.attr \disabled on
		$submit-button.text 'Updating'
		$form.find \textarea .attr \disabled on

		$.ajax "#{config.web-api-url}/posts/status" {
			data:
				'text': ($form.find \textarea .val!)}
		.done (data) ->
			window.display-message '投稿しました！'
			$form[0].reset!
			$submit-button.attr \disabled off
			$form.find \textarea .attr \disabled off
			THIS.postForm.close!
		.fail (data) ->
			window.display-message '投稿に失敗しました。'
			$submit-button.attr \disabled off
			$form.find \textarea .attr \disabled off
			$submit-button.text 'Re Update'

	focus: ->
		THIS = @
		THIS.postForm.tab.select \status no
		$ \#misskey-post-form-status-tab-page .find \textarea .focus!

class PhotoPostForm
	(postForm) ->
		THIS = @
		THIS.postForm = postForm

		Sortable.create ($ '#misskey-post-form-photo-tab-page > .photos')[0], {
			animation: 150ms
		}

		sncompleter $ '#misskey-post-form-photo-tab-page textarea'

		$ '#misskey-post-form-photo-tab-page textarea' .on \paste (event) ->
			items = (event.clipboard-data || event.original-event.clipboard-data).items
			for i from 0 to items.length - 1
				item = items[i]
				if item.kind == \file && item.type.index-of \image != -1
					file = item.get-as-file!
					THIS.postForm.photoPostForm.upload-new-file file

		$ '#misskey-post-form-photo-tab-page textarea' .keypress (e) ->
			if (e.char-code == 10 || e.char-code == 13) && e.ctrl-key
				THIS.submit!

		$ '#misskey-post-form-photo-tab-page > .attach-from-album' .click ->
			window.open-select-album-file-dialog (files) ->
				files.for-each (file) ->
					THIS.add-file file

		$ '#misskey-post-form-photo-tab-page > .attach-from-local' .click ->
			$ '#misskey-post-form-photo-tab-page > input[type=file]' .click!
			false

		$ '#misskey-post-form-photo-tab-page > input[type=file]' .change ->
			files = ($ '#misskey-post-form-photo-tab-page > input[type=file]')[0].files
			for i from 0 to files.length - 1
				file = files.item i
				THIS.upload-new-file file

		$ \#misskey-post-form-photo-tab-page .submit (event) ->
			event.prevent-default!
			THIS.submit!

	add-file: (file-data) ->
		$thumbnail = $ "<li style='background-image: url(#{file-data.url});' data-id='#{file-data.id}' />"
		$remove-button = $ '<button class="remove" title="添付を取り消し"><img src="/resources/desktop/images/form-file-thumbnail-remove.png" alt="remove"></button>'
		$thumbnail.append $remove-button
		$remove-button.click ->
			$thumbnail.remove!
		$ '#misskey-post-form-photo-tab-page > .photos' .append $thumbnail

	upload-new-file: (file) ->
		THIS = @
		THIS.postForm.upload-file file, ($ '#misskey-post-form-photo-tab-page'), (html) ->
			THIS.add-file JSON.parse ($ html).attr \data-data

	submit: ->
		THIS = @

		$form = $ \#misskey-post-form-photo-tab-page
		$submit-button = $form.find '[type=submit]'

		$submit-button.attr \disabled on
		$submit-button.text 'Updating'
		$form.find \textarea .attr \disabled on

		$.ajax "#{config.web-api-url}/posts/photo" {
			data:
				'text': ($form.find \textarea .val!)
				'photos': JSON.stringify(($form.find '.photos > li' .map ->
					($ @).attr \data-id).get!)
		}
		.done (data) ->
			window.display-message '投稿しました！'
			$form[0].reset!
			$submit-button.attr \disabled off
			$form.find \textarea .attr \disabled off
			THIS.postForm.close!
		.fail (data) ->
			window.display-message '投稿に失敗しました。'
			$submit-button.attr \disabled off
			$form.find \textarea .attr \disabled off
			$submit-button.text 'Re Update'

	focus: ->
		THIS = @
		THIS.postForm.tab.select \photo no
		$ \#misskey-post-form-photo-tab-page .find \textarea .focus!

$ ->
	postForm = new PostForm

	update-header-statuses!
	set-interval update-header-statuses, 10000ms

	update-header-clock!
	set-interval update-header-clock, 1000ms

	$ '#misskey-main-header > .main .mainContentsContainer .left nav .mainNav ul .talk a' .click ->
		window-id = "misskey-window-talk-histories"
		$content = $ '<iframe>' .attr {src: '/i/talks', +seamless}
		window.open-window do
			window-id
			$content
			"<i class=\"fa fa-comments\"></i>トーク"
			500px
			560px
			yes
			'/i/talks'
		false

	$ \body .css \margin-top "#{$ 'body > #misskey-main-header' .outer-height!}px"

	# 「Misskey Menu」ドロップダウン
	$ '#misskey-main-header .misskey-menu .dropdown .dropdown-header' .click ->
		$dropdown = $ '#misskey-main-header .misskey-menu .dropdown'

		function close
			$dropdown.attr \data-active \false

		function open
			$ document .click (e) ->
				if !$.contains $dropdown[0], e.target
					close!
			$dropdown.attr \data-active \true

		if ($dropdown.attr \data-active) == \true
			close!
		else
			open!

	# Talks
	$ '#misskey-main-header > .main .main-contents-container .left nav .main-nav ul .talk a' .click ->
		window-id = "misskey-window-talk-histories"
		$content = $ '<iframe>' .attr {src: '/i/talks-widget', +seamless}
		ui-window do
			window-id
			$content
			"<i class=\"fa fa-comments\"></i>トーク"
			500px
			560px
			yes
			'/i/talks-widget'
		false

	# 「アカウント」ドロップダウン
	$ '#misskey-main-header .account .dropdown .dropdown-header' .click ->
		$dropdown = $ '#misskey-main-header .account .dropdown'

		function close
			$dropdown.attr \data-active \false
			$dropdown.find 'i.fa.fa-angle-up' .attr \class 'fa fa-angle-down'

		function open
			$ document .click (e) ->
				if !$.contains $dropdown[0], e.target
					close!
			$dropdown.attr \data-active \true
			$dropdown.find 'i.fa.fa-angle-down' .attr \class 'fa fa-angle-up'

		if ($dropdown.attr \data-active) == \true
			close!
		else
			open!

	# 通知全削除ﾎﾞﾔﾝ
	$ '#misskey-main-header .notifications .delete-all-button' .click ->
		$ '#misskey-main-header .notifications .notification' .each (i) ->
			$notification = $ @
			set-timeout ->
				$notification.transition {
					perspective: \4096px
					rotate-x: \90
					opacity: \0
				} 200ms \ease ->
					$message.remove!
			, i * 50

		$.ajax config.web-api-url + '/notification/delete-all'
		.done (data) ->
			$ '#misskey-main-header .notifications .unread-count' .remove!
			$list = $ '<ol class="notifications" />'
			$info = $ '<p class="notification-empty">通知はありません</p>'
			$info.append-to $notifications-container
		.fail (data) ->

	# 「通知」ドロップダウン
	$ '#misskey-main-header .notifications .dropdown .dropdown-header' .click ->
		$dropdown = $ '#misskey-main-header .notifications .dropdown'

		function close
			$dropdown.attr \data-active \false
			$ '#misskey-main-header .notifications .dropdown .dropdown-content .main' .empty!

		function open
			$ document .click (e) ->
				if !$.contains $dropdown[0], e.target
					close!
			$dropdown.attr \data-active \true

			$notifications-container = $ '#misskey-main-header .notifications .dropdown .dropdown-content .main'
			$ '<img class="loading" src="/resources/images/notifications-loading.gif" alt="loading..." />' .append-to $notifications-container

			# 通知読み込み
			$.ajax config.web-api-url + '/notification/timeline-webhtml'
			.done (data) ->
				$ '#misskey-main-header .notifications .loading' .remove!
				$ '#misskey-main-header .notifications .unread-count' .remove!
				$list = $ '<ol class="notifications" />'
				if data != ''
					$ '#misskey-main-header .notifications .nav' .css \display \block
					$ '#misskey-main-header .notifications .main' .css \margin-top \32px
					$notifications = $ data
					$notifications.each ->
						$notification = $ @
						$notification.append-to $list
					$list.append-to $notifications-container
				else
					$info = $ '<p class="notification-empty">通知はありません</p>'
					$info.append-to $notifications-container
			.fail (data) ->
				$ '#misskey-main-header .notifications .loading' .remove!

		if ($dropdown.attr \data-active) == \true
			close!
		else
			open!

	$ '#misskey-main-header .search input' .bind \input ->
		$input = $ @
		$result = $ '#misskey-main-header .search .result'
		if $input .val! == ''
			$input.attr \data-active \false
			$result.empty!
		else
			$input.attr \data-active \true
			$.ajax "#{config.web-api-url}/users/search" {
				data: {'query': $input .val!}
				data-type: \json}
			.done (result) ->
				$result.empty!
				if (result.length > 0) && ($input .val! != '')
					$result.append $ '<ol class="users">'
					result.for-each (user) ->
						$result.find \ol .append do
							$ \<li> .append do
								$ '<a class="ui-waves-effect">' .attr {
									'href': "#{config.url}/#{user.screen-name}"
									'title': user.comment}
								.append do
									$ '<img class="avatar" alt="avatar">' .attr \src user.avatar-url
								.append do
									$ '<span class="name">' .text user.name
								.append do
									$ '<span class="screen-name">' .text "@#{user.screen-name}"
					window.init-waves-effects!
			.fail ->

	$ \#misskey-main-header-i-settings-anchor .click ->
		$.ajax config.url + '/i/settings' {
			type: \get
			data-type: \html}
		.done (data) ->
			$dialog = $ '<div id="misskey-i-settings-form" />'
			$dialog.append ($ data).find \main
			init-i-settings-dialog $dialog.find \main
			show-modal-window $dialog
		.fail (data) ->
		false

$ window .load ->
	header-height = $ 'body > #misskey-main-header' .outer-height!
	$ \body .css \margin-top "#{header-height}px"

	WavesEffect.attach-to-class \ui-waves-effect
