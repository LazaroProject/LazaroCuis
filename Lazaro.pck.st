'From Cuis 5.0 of 7 November 2016 [latest update: #3345] on 21 July 2018 at 11:04:21 pm'!
'Description Lazaro for CUIS'!
!provides: 'Lazaro' 1 1!
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

!ScreenReader class methodsFor: 'as yet unclassified' stamp: 'GC 7/21/2018 21:30:34'!
say: someText

	usingTTS ifNil: [ usingTTS := false ].
	
	usingTTS ifTrue: [ OSProcess command: ('say ', someText) ] ifFalse: [ Transcript show: someText; nl ]! !

!ScreenReader class methodsFor: 'as yet unclassified' stamp: 'GC 7/21/2018 21:11:10'!
useTTS

	usingTTS := true.! !

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
