exports.render = !->
	task = Page.state.get 0
	edit = Page.state.get 1
	if task is 'new'
		renderEdit()
	else if +task and edit is 'edit'
		renderEdit +task
	else if +task
		renderView +task
	else
		renderTasks()

renderTasks = !->
	tasks = Db.shared.ref 'tasks'

	# Add task button
	Page.setActions
		icon: 'add'
		label: 'Add task'
		action: !-> Page.nav 'new'

	Dom.h1 "Week "+getWeekNumber()

	# Gather users
	userIds = []
	for id,user of App.users.get()
		userIds.push(+id)
	userIds.sort()

	# Gather tasks
	taskKeys = []
	for taskKey,task of tasks.get()
		taskKeys.push(+taskKey)
	taskKeys.sort()

	log "userIds:", userIds, "taskKeys:", taskKeys

	if taskKeys.length is 0
		Ui.emptyText "Create a task using the button above"
		return

	# Weeks since Epoch, add 3 to get boundary right
	weekOffset = Math.round((new Date()).getTime()/1000/60/60/24/7)
	for userId,index in userIds
		log "Userid:", userId, "index:", index
		Dom.div !->
			Dom.style
				Box: 'horizontal'
				padding: '10px 0'

			# Name
			Ui.avatar App.userAvatar(userId)
			Dom.div !->
				Dom.style
					fontSize: '18px'
					fontWeight: 'bold'
					padding: '10px 25px 0 10px'
					minWidth: '100px'
				Dom.text App.userName(userId)

			# Tasks
			Dom.div !->
				Dom.style Flex: true
				# Give tasks while still in range
				count = 0
				extra = ((+index)+weekOffset) % userIds.length
				while (taskIndex = count*userIds.length+extra) < taskKeys.length
					log "taskIndex:", taskIndex, "extra:", extra, "count:", count
					Dom.div !->
						task = tasks.ref([taskKeys[taskIndex]])

						Dom.style marginBottom: '5px'

						Dom.div !->
							Dom.style fontSize: '18px'
							Dom.userText task.get('name')
						Dom.div !->
							Dom.style fontSize: '14px'
							Dom.userText task.get('description')
						Dom.onTap !->
							Page.nav task.key()
					count++
				if count is 0
					Ui.emptyText "No task for you this week!"

renderEdit = (id) !->
	Page.setActions
		icon: 'trash'
		label: 'Delete task'
		action: !->
			Modal.confirm "Delete the task?", !->
				Dom.div !->
					Dom.h1 task.get('name')
					Dom.userText task.get('description')
				Dom.div !->
					Dom.style fontWeight: 'bold', marginTop: '20px'
					Dom.text "Are you sure you want to delete this task?"
			, !->
				Server.sync 'delete', id, !->
					Db.shared.remove 'tasks', id
				Page.up()
				Page.up()

	task = Db.shared.ref 'tasks', id
	if task.get()
		Page.setTitle "Editing task"
	else
		Page.setTitle "Add task"

	# Name input
	Form.input
		name: 'name'
		value: task.get('name')
		text: 'Name'
	Form.condition (values) !->
		if !values.name
			return "Enter a task name"

	# Description input
	Form.text
		name: 'description'
		value: task.get('description')
		text: 'Description'
	Form.condition (values) !->
		if !values.description
			return "Enter a task description"

	# Submit
	Form.setPageSubmit (values) !->
		Server.sync 'task', id, values, !->
			if id
				Db.shared.set 'tasks', id, values
			else
				Db.shared.set 'tasks', Math.round(Math.random()*100000), values
		Page.up()


renderView = (id) !->
	# Add task button
	Page.setActions
		icon: 'edit'
		label: 'Edit task'
		action: !-> Page.nav [id, 'edit']

	task = Db.shared.ref 'tasks', id
	if !task
		Ui.emptyText ("Wrong task: "+id)
		return

	Dom.h1 task.get('name')
	Dom.div !->
		Dom.style
			fontSize: '18px'
		Dom.userText task.get('description')


getWeekNumber = ->
	d = new Date()
	d.setHours(0, 0, 0, 0)
	d.setDate(d.getDate() + 4 - (d.getDay() || 7))
	yearStart = new Date(d.getFullYear(), 0, 1)
	weekNo = Math.ceil(( ( (d - yearStart) / 86400000) + 1) / 7)
	return weekNo