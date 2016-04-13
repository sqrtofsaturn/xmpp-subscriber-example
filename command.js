'use strict';

require('coffee-script/register');
var Command = require('./command.coffee');
var command = new Command();
command.run(process.argv);
