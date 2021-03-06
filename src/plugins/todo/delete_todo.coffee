module.exports = (args, done)->
  {id} = args
  if !id
    err_opts =
      role: 'util'
      cmd: 'missing_args'
      service: 'todo'
      name: 'delete_todo'
      given: @util.clean args
    act err_opts
    .then _handle_error done
  else
    add_opts =
      role: 'db'
      cmd: 'destroy'
      query:
        primary_key: id
      model: 'Todo'
    act add_opts
    .then (todo)->
      done null, data: todo
    .catch _handle_error done
