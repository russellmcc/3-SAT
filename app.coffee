require ['ember-0.9.5.min'], ->
  # make the main namespace.
  window.App = Ember.Application.create()

  #  The puzzle is a series of clauses.  Each clause
  # has 3 letters in it.  In each clause, one letter
  # must be chosen.  However, if an inverted letter is
  # chosen, a non-inverted letter of the same letter
  # may never be chosen and vice-versa.
  createLetter = -> Ember.Object.create
    letter: 'A'
    invert: false
    isSelected: false

  createClause = -> Ember.Object.create
    letters: []
    chosenPrivate: null
    chosen: (Ember.computed (key, chosenLetter) ->
      if arguments.length > 1
        (@get 'letters').forEach (letter) =>
          if(chosenLetter is letter)
            letter.set 'isSelected', true
            @set 'chosenPrivate', letter
          else
            letter.set 'isSelected', false
      else
        return @get 'chosenPrivate'
      ).property('chosenPrivate')
    conflicting: false

  App.ClauseView = Ember.View.extend
    templateName: 'clause-view'
    select: (view, event, ctx) ->
      @content.set 'chosen', ctx


  # this is kinda the controller for everything.
  App.puzzleController = Ember.Object.create
    clauses: []

    # Generates a new puzzle from a string.
    resetPuzzle : (puzzleString) ->
      if (@get 'clauses').length
        (@get 'clauses').removeAt(0, (@get 'clauses').length )
      for i in [0...(puzzleString.length / 3)]
        clause = createClause()
        letters = for n in [0..2]
          puzzleString[i*3 + n]
        for letter in letters
          l = createLetter()
          l.set 'letter', letter.toUpperCase()
          l.set 'invert', letter is letter.toLowerCase()
          (clause.get 'letters').pushObject l
        (@get 'clauses').pushObject clause

    # get all the letters chosen by any clause.
    chosen: (Ember.computed ->
        allChosen = []
        (@get 'clauses').forEach (clause) ->
          chosen = clause.get 'chosen'
          allChosen.push(chosen) if chosen?

        # cull the duplicated letters!
        retVal = []
        for chosen in allChosen
          needToAdd = true
          for val in retVal
            if ((val.get 'letter') is (chosen.get 'letter') and (val.get 'invert') is (chosen.get 'invert'))
              needToAdd = false
          retVal.push(chosen) if needToAdd

        # finally, sort.
        retVal = retVal.sort (a, b) ->
          return (a.get 'letter').charCodeAt(0) - (b.get 'letter').charCodeAt(0)
        retVal
      ).property('clauses.@each.chosen').cacheable()

    # did we solve the puzzle?
    solved: (Ember.computed ->
        retVal = true

        # we've solved the puzzle if every clause is valid.
        (@get 'clauses').forEach (clause) =>
          chosen = clause.get 'chosen'

          # if we haven't chosen anything, we're not valid.
          if not chosen?
            retVal = false
            clause.set 'conflicting', false
            return


          # check if conflicts with any other clause
          conflicts = false
          (@get 'clauses').forEach (other) =>
            otherChose = other.get 'chosen'
            if otherChose? and ((otherChose.get 'letter') is (chosen.get 'letter')) and ((otherChose.get 'invert') isnt (chosen.get 'invert'))
                retVal = false
                conflicts = true
          # update the conflicting flag.
          clause.set 'conflicting', conflicts

          # if any clause conflicts, we all fail.
          if conflicts
            retVal = false

        retVal
      ).property('clauses.@each.chosen').cacheable()


  App.puzzleController.resetPuzzle (getParameterByName('puzzle') ? 'AbCabcGeF')
