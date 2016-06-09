module ApplicationHelper
	# Array of all restaurant categories
	def get_categories
			# all must be lower case
			["polska","włoska","francuska","japońska",
				"środkowowschodnia","chińska","wegetariańska","pizzeria",
				"fast food","burger","studencka","austriacka","europejska",
				"izraelska","polinezyjska","posiłki bezglutenowe","fusion",
				"hawajska","nowozelandzka","australijska","polinezyjska",
				"międzynarodowa"]
	end
	

	def sortable(title = nil,column)
	  title ||= column.titleize
	  link_to title, {:sort => column}
	end


end