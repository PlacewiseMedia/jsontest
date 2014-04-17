# jsontest

> Test your JSON output with JSON tests using JSON rules resulting in JSON output, which can then be tested with more JSON.

[Yo dawg...](http://i.imgur.com/V9utvES.png)

## Getting Started

If you haven't used [grunt][] before, be sure to check out the [Getting Started][] guide, as it explains how to create a [gruntfile][Getting Started] as well as install and use Grunt plugins. Once you're familiar with that process, install this plugin with this command:

```bash
$ npm install jsontest --save-dev
```

Once the plugin has been installed, it may be enabled inside your Gruntfile with this line of JavaScript:

```js
grunt.loadNpmTasks('jsontest');
```

*Tip: the [load-grunt-tasks](https://github.com/sindresorhus/load-grunt-tasks) module makes it easier to load multiple grunt tasks.*

[Grunt]: http://gruntjs.com
[Getting Started]: https://github.com/gruntjs/grunt/wiki/Getting-started

## Validators

jsontest provides several powerful means of writing a particular assertion. There may be some overlap in what's available to validate a value against. Use whichever means makes most sense for your application.

### iz Rules

A target can assert with a JSON object assigned to the `rules` property. This allows one to write assertion validation rules using the [iz library's JSON interface](https://github.com/parris/iz#json). Some validators it supports are listed here:

Method                          | Function
------------------------------: | :---------------------------------------------------------------------------
alphaNumeric(*);                | Is number or string(contains only numbers or strings)
between(number, start, end);    | Number is start or greater but less than or equal to end, all params numeric
blank(*);                       | Empty string
boolean(*);                     | true, false, 0, 1
cc(*);                          | Luhn checksum approved value
date(*);                        | Is a date obj or is a string that is easily converted to a date
decimal(*);                     | int or float
email(*);                       | Seems like a valid email address
empty(*);                       | If an object, array or function contains no properties true. All primitives return true.
equal(*, *);                    | Any 2 things are strictly equal. If 2 objects their internal properties will be checked. If the first parameter has an equals method that will be run instead
extension(ob1, ob2);            | If obj2's methods are all found in obj1
fileExtension(value, arr);      | Checks if the extension of value is in arr. An obj can be provide, but must have indexOf defined.
fileExtensionAudio(value);      | Check against mp3, ogg, wav, aac
fileExtensionImage(value);      | Check against png, jpg, jpeg, gif, bmp, svg, gif
inArray(value, arr);            | If * is in the array
int(*, bool (optional));        | Is an int. If the 2nd variable is true (false by default) a decimal is allowed
ip(str);                        | str resembles an IPV4 or IPV6 address
minLength(val, min);            | val (str or arr) is greater than min
maxLength(val, max);            | val (str or arr) is shorter than max
multiple(num, mult);            | Number is multiple of another number
number(*);                      | Is either an int or decimal
ofType(obj, typeName);          | If it is a named object, and the name matches the string
phone(str, canHaveExtension?);  | Is an american phone number. Any punctuations are allowed.
postal(*);                      | Is a postal code or zip code
required(*);                    | Is not null, undefined or an empty string
ssn(*);                         | Is a social security number
string(*);                      | Is the argument of type string

### Math.js Expressions

It's also possible to use an inequality or other mathematical expression that is evaluated using a string in the [Math.js](http://mathjs.org/) expression format. As long as the value is included as part of the expression, it can be used with numbers declared within that expression.

For example:

```
"length": "val > 0"
```