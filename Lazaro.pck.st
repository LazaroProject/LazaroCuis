'From Cuis 5.0 of 7 November 2016 [latest update: #3345] on 26 July 2018 at 12:31:52 am'!
'Description Lazaro for CUIS'!
!provides: 'Lazaro' 1 4!
!requires: 'OSProcess' 1 6 nil!
!requires: 'SqueakCompatibility' 1 28 nil!
SystemOrganization addCategory: #Lazaro!


!classDefinition: #ScreenReader category: #Lazaro!
Object subclass: #ScreenReader
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Lazaro'!
!classDefinition: 'ScreenReader class' category: #Lazaro!
ScreenReader class
	instanceVariableNames: 'usingTTS'!


!ScreenReader class methodsFor: 'as yet unclassified' stamp: 'GC 7/21/2018 21:31:51'!
doNotUseTTS

	usingTTS := false! !

!ScreenReader class methodsFor: 'as yet unclassified' stamp: 'GC 7/22/2018 16:21:32'!
humanize: aText

	^ aText string withBlanksCondensed! !

!ScreenReader class methodsFor: 'as yet unclassified' stamp: 'GC 7/26/2018 00:30:34'!
say: aText
	| humanizedText command |
	
	humanizedText := self humanize: aText.
	command := 'say ', humanizedText surroundedBySingleQuotes.
	
	usingTTS ifNil: [ usingTTS := false ].	
	usingTTS ifTrue: [ OSProcess command: (command) ] 
				ifFalse: [ Transcript show: command; nl ]! !

!ScreenReader class methodsFor: 'as yet unclassified' stamp: 'GC 7/21/2018 23:28:07'!
switchTTSUsage

	usingTTS := usingTTS not! !

!ScreenReader class methodsFor: 'as yet unclassified' stamp: 'GC 7/21/2018 21:11:10'!
useTTS

	usingTTS := true.! !

!ScreenReader class methodsFor: 'as yet unclassified' stamp: 'GC 7/21/2018 23:12:27'!
usingTTS

	^ usingTTS! !

!SystemWindow methodsFor: '*Lazaro' stamp: 'GC 7/21/2018 21:23:59'!
activateAndSendTopToBack: aBoolean
	"Bring me to the front and make me able to respond to mouse and keyboard"

	| oldTop |
	owner 
		ifNil: [^self	"avoid spurious activate when drop in trash"].
	oldTop _ TopWindow.
	TopWindow _ self.
	
	ScreenReader say: self label, ' on focus'.

	oldTop ifNotNil: [
		oldTop redrawNeeded.
		aBoolean ifTrue: [
			| bottomWindow |
			bottomWindow _ oldTop owner submorphs reverse detect: [:one | one is: #SystemWindow].
			oldTop owner addMorph: oldTop behind: bottomWindow]].

	owner firstSubmorph == self 
		ifFalse: [
			"Bring me to the top if not already"
			owner addMorphFront: self].
	self redrawNeeded.

	"Set keyboard focus"
	self world ifNotNil: [ :w |
		w activeHand newKeyboardFocus: self submorphToFocusKeyboard ]! !

!MenuMorph methodsFor: '*Lazaro' stamp: 'GC 7/18/2018 23:59:56'!
title

	(titleMorph isNil) ifTrue: [ ^ self className] ifFalse: [ ^ (titleMorph  submorphs at: 1) contents ]! !

!MenuItemMorph methodsFor: '*Lazaro' stamp: 'GC 7/21/2018 22:26:53'!
select
	self isSelected: true.
	ScreenReader say: self contents.
	owner activeSubmenu: subMenu.
	subMenu ifNotNil: [
		subMenu delete.
		subMenu
			popUpAdjacentTo: (Array with: self morphBoundsInWorld topRight + `10@0`
											with: self morphBoundsInWorld topLeft)
			from: self.
		subMenu selectItem: nil ]! !

!InnerListMorph methodsFor: '*Lazaro' stamp: 'GC 7/21/2018 23:01:58'!
selectedRow: index
	"select the index-th row.  if nil, remove the current selection"
	selectedRow _ index.
	highlightedRow _ nil.
	ScreenReader say: self selectedRowName.
	self redrawNeeded! !

!InnerListMorph methodsFor: '*Lazaro' stamp: 'GC 7/21/2018 23:00:50'!
selectedRowName
	
	(selectedRow = 0) ifTrue: [ ^ '' ] ifFalse: [ ^ self item: self selectedRow ]! !

!InnerTextMorph methodsFor: '*Lazaro' stamp: 'GC 7/22/2018 03:32:19'!
contents

	^ model actualContents! !

!InnerTextMorph methodsFor: '*Lazaro' stamp: 'GC 7/22/2018 03:36:53'!
processKeyStroke: evt
	| action |

	(acceptOnCR and: [evt isReturnKey])
		ifTrue: [^ self acceptContents].

	self pauseBlinking.
	evt isReturnKey ifTrue: [	"Return - check for special action"
		action _ self crAction.
		action ifNotNil: [
			^action value]].
	evt anyModifierKeyPressed ifTrue: [ (evt keyCharacter == $r) ifTrue: [ ScreenReader say: self contents ] ].
	self handleInteraction: [ editor processKeyStroke: evt ].

	"Is this really needed? It produces whole morph invalidation just by (for example)
	moving the cursor around... (jmv Aug 6, 2014)"
	"self updateFromTextComposition."

	self scrollSelectionIntoView! !

!TheWorldMenu methodsFor: '*Lazaro' stamp: 'GC 7/22/2018 02:52:05'!
preferencesMenu
	"Build the preferences menu for the world."

	^ (self menu: 'Preferences...')
		addItemsFromDictionaries: `{
			{
				#label 			-> 		'Focus follows mouse'.
				#object 			-> 		Preferences.
				#selector 		-> 		#enableFocusFollowsMouse.
				#icon 			-> 		#windowIcon.
				#balloonText 	-> 		'At all times, make the active window and widget the one on which the mouse is located.'
			} asDictionary.
			{
				#label 			-> 		'Click to focus'.
				#object 			-> 		Preferences.
				#selector 		-> 		#disableFocusFollowsMouse.
				#icon 			-> 		#windowIcon.
				#balloonText 	-> 		'At all times, make the active window and widget the one where the mouse was clicked.'
			} asDictionary.
			{
				#label 			-> 		'Font Sizes...'.
				#object 			-> 		Theme.
				#selector 		-> 		#changeFontSizes.
				#icon 			-> 		#preferencesDesktopFontIcon.
				#balloonText 	-> 		'use larger or smaller text and widgets'
			} asDictionary.
			{
				#label 			-> 		'Switch Lazaro TTS'.
				#object 			-> 		ScreenReader.
				#selector 		-> 		#switchTTSUsage.
				#icon 			-> 		#switchIcon.
				#balloonText 	-> 		'Switches the Lazaro TTS usage'				
			} asDictionary.
			{
				#label 			-> 		'Icons...'.
				#object 			-> 		Theme.
				#selector 		-> 		#changeIcons.
				#icon 			-> 		#worldIcon.
				#balloonText 	-> 		'show more or less icons.'
			} asDictionary.
			{
				#label 			-> 		'Themes...'.
				#object 			-> 		Theme.
				#selector 		-> 		#changeTheme.
				#icon 			-> 		#appearanceIcon.
				#balloonText 	-> 		'switch to another theme.'
			} asDictionary.
			nil.
			{
				#label 			-> 		'Show taskbar'.
				#object 			-> 		#myWorld.
				#selector 		-> 		#showTaskbar.
				#icon 			-> 		#expandIcon.
				#balloonText 	-> 		'show the taskbar'
			} asDictionary.
			{
				#label 			-> 		'Hide taskbar'.
				#object 			-> 		#myWorld.
				#selector 		-> 		#hideTaskbar.
				#icon 			-> 		#collapseIcon.
				#balloonText 	-> 		'hide the taskbar'
			} asDictionary.
			nil.
			{
				#label 			-> 		'Full screen on'.
				#selector 		-> 		#fullScreenOn.
				#icon 			-> 		#viewFullscreenIcon.
				#balloonText 	-> 		'puts you in full-screen mode, if not already there.'
			} asDictionary.
			{
				#label 			-> 		'Full screen off'.
				#selector 		-> 		#fullScreenOff.
				#icon 			-> 		#exitFullscreenIcon.
				#balloonText 	-> 		'if in full-screen mode, takes you out of it.'
			} asDictionary.
			nil.
			{
				#label 			-> 		'Set Code Author...'.
				#object 			-> 		Utilities.
				#selector 		-> 		#setAuthor.
				#icon 			-> 		#usersIcon.
				#balloonText 	-> 		'supply initials to be used to identify the author of code and other content.'
			} asDictionary.
			{
				#label 			-> 		'All preferences...'.
				#object 			-> 		Preferences.
				#selector 		-> 		#openPreferencesInspector.
				#icon 			-> 		#preferencesIcon.
				#balloonText 	-> 		'view and change various options.'
			} asDictionary.
		}`! !
