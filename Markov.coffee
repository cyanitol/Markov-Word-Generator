###
Markov.coffee - Markov chains in CoffeeScript.
github.com/SyntaxColoring/Markov-Word-Generator

Released under the MIT license.

Copyright (c) 2013 SyntaxColoring
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###

class Markov
	# Creates a new Markov chain from the given array of sequences
	# (to use as a corpus) and value for n (to use as the Markov order).
	# sequences may be empty. n must be an integer no lower than 0.
	# Feel free to directly access and modify an object's .sequences and .n.
	constructor: (@sequences = [], @n = 2) ->
	
	# Generates a new pseudorandom sequence generated by the Markov chain and
	# returns it as an array.  Its length will be truncated to maxLength if necessary.
	generate: (maxLength = 20) ->
		result = []
		currentState = => # Returns at most the last @ elements of result.
			result[Math.max(0, result.length-@n)...result.length]
		continuation = => @continue(currentState())
		while result.length < maxLength and (nextElement = continuation())?
			result.push nextElement
		return result
		
	# Returns in an array the n-grams that went into making the Markov chain
	# Note that the size of the n-grams will always be one greater than the
	# Markov order - if a Markov chain was created with n=2, this method
	# will return an array of 3-grams.
	ngrams: ->
		ngramsFromSequence = (sequence, n) ->
			if n < 1 or n > sequence.length then []
			else sequence[i...i+n] for i in [0..sequence.length-n]
		@sequences.reduce ((a, b) => a.concat ngramsFromSequence b, @n+1), []
	
	# Builds a probability tree and returns the node of the given sequence, or
	# the root node if no sequence is specified.  Returns null if the given
	# sequence is not represented in the tree.
	# 
	# Each node has a "count", "frequency" and "continuations" property.
	# For example:
	#   node = myMarkov.tree("abc")
	#   c = node.continuations["d"].count
	#   f = node.continuations["d"].frequency
	# c would be the number of times that "d" came after "abc" in the original corpus.
	# f would be the probability that the letter to follow "abc" is "d."
	tree: (sequence = []) ->
		ngrams = @ngrams()
		root = { continuations: {}, count: ngrams.length, frequency: 1.0 }
	
		# Build the tree and supply each node with its count property.
		for ngram in ngrams
			node = root
			for element in ngram
				unless node.continuations[element]?
					# If we need to create a new node, do so.
					node.continuations[element] = { continuations: {}, count: 0 }
				node = node.continuations[element]
				node.count++
		
		# Recursively descend through the tree we just built and give each node its
		# frequency property.
		normalize = (node) ->
			for childName, child of node.continuations
				child.frequency = child.count / node.count
				normalize child
		
		normalize root
		
		# Navigate to the desired sequence.
		sequence = sequence.split("") if typeof sequence is "string"
		reduce = (node, element) ->
			if node? then node.continuations[element] ? null else null
		sequence.reduce reduce, root
		
	# Uses the Markov chain to pick the next element to come after sequence.
	# Returns null if there are no possible continuations.
	continue: (sequence) ->
		node = @tree(sequence)
		if node?
			target = Math.random()
			sum = 0
			for continuationName, continuationNode of node.continuations
				sum += continuationNode.frequency
				if sum >= target then return continuationName
		return null # Either the node was null or it had no continuations.

(exports ? window).Markov = Markov
