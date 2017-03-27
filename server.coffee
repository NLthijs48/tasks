exports.onInstall = !->

exports.client_task = (id, data) !->
  # Validate
  if !data.name
    log "[task] #{user()} id:", id, "no name provided:", JSON.stringify(data)
  if !data.description
    log "[task] #{user()} id:", id, "no description provided:", JSON.stringify(data)

  # Assign id if new
  if !id
    data.created = new Date()/1000
    data.createdBy = App.userId()
    id = Db.shared.incr 'taskMax'
  else
    data.edited = new Date() / 1000
    data.editedBy = App.userId()
  log "[task] #{user()} id:", id, "data:", JSON.stringify(data)

  Db.shared.set 'tasks', id, data


exports.client_delete = (id) !->
  log "[delete] #{user()} id:", id
  Db.shared.remove 'tasks', id

user = (userId) !->
  App.userName(userId)+"("+App.userId(userId)+")"