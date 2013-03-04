# MagicScopes

MagicScopes is the scopes generator for ActiveRecord.
It adds magic_scopes method (and nothing else) to ActiveRecord::Base.
It depends on ActiveRecord and ActiveSupport and can be used without Rails.
MagicScopes module should be included manually in the latter case.
It also has support for the StateMachine gem and can generate scopes for states.

Code speaks much louder than words, so I show you some usage examples at first.

## Usage examples

* Call to `magic_scopes` without parameters generates all possible scopes for all attributes, belongs_to associations and states. It also generates asc, sorted, desc, recent, random standard scopes (read further for details). By specifying parameters you tell magic_scopes to generate only the scopes you need.

* You can customize change by specifying list of attributes and options, (all options accept strings, symbols and arrays as arguments).

* `magic_scopes :title, :bogus` generates all possible scopes for title and bogus attributes.

* You can specify in (stands for include) and ex (for exclude) options, so:
  * `magic_scopes in: %w(with by), std: %w(recent random)` generates 'with' and 'by' scopes for all suitable attributes and 'recent' and 'random' standard scopes.
  * `magic_scopes ex: %w(with by)` generates all possible scopes except 'with' and 'by' ones when 'ex' option is specified.
  * `magic_scopes :title, :bogus, in: %w(with by)` generates 'with' and 'by' scopes for all suitable attributes in specified list when both attributes list and in options are cpecified:
  * You can also override scopes that should be generated per attribute:
      `magic_scopes :title, :rating, bogus: :by_desc, in: %w(with by)` generates with and by scopes for title and rating attributes and by_desc scope for bogus attribute.
  * Also you can specify scope name for scope type per attribute, like so: `magic_scopes :title, rating: {by_desc: :by_popularity}`. It generates all possible scopes for title attribute and 'by_popularity' scope that sorts relation by rating, desc.


## MagicScopes can generate these scopes:

* **with** and **without** options generates scopes such as **with_rating**, **without_rating** that will look for non-null and null values, respectively. For state attributes they redefine corresponding state_machine scopes so they can be called without parameters to check against null and non-null. (You can use it in the normal way too, of course). These scopes can be used with boolean, state, integer, decimal, time, date, datetime, float and string attributes. For integer, decimal, time, date, datetime and string attributes value(s) can be passed to the scope so the check will be performed against passed values (not against null/non-null vakues). (ex.: with_rating(1,2,3), without_rating([5,4,3]))
* **is** and **not** options generates scopes such as **published**, **not_published** ("is" is the one option that is not reflected in the name of the generated scope) that look for true and and false or null values for boolean attributes and for the specified state and for state that is not the specifieed one no null for state attributes.
* **eq** (stands for equal), **ne** (not equal), **gt** (greater than), **gte** (greater than or equal), **lt** (lesser than), **lte** (lesser than or equal) options generate scopes with corresponding suffixes and accept list of values or array as parameteters. Options names are self explanatory. These scopes can be used with integer, decimal, time, date and datetime attributes. lt and gt options can be used with float attributes.
* for string attributes **like** and **ilike** options can be specified which generate scopes like **title_like**, **title_ilike** which accept list or array of arguments and look for values like the specified ones, case sensitive and insensitive, respectively.
* **by** and **by_desc** options can be used with integer, decimal, time, date, datetime, float and string attributes and generate scopes like **by_created_at** and **by_created_at_desc**, which sort by created at asc and created at desc, respectively.
* **for** and **not_for** scopes can be used with belongs_to associations (including polymorphic ones) and generate scopes like **for_user**, **not_for_commentable**. They can accept list or array of associations. Also, hash(es) with id and type keys can be specified for polymorphic associations.


## Standard scopes

In addition, some standard scopes can be specified using :std option, they are:
asc and sorted sort by id asc, desc and recent sort by id desc and random sorts in random order.
ex.: magic_scopes :title, :bogus, in: %w(with without), std: %w(recent rendom)
magic_scopes generate all possible standard scopes unless std option is specified.

MagicScopes is thoroughly tested and ready for production.
It works with ActiveRecord >= 3.0 and ruby 1.9. (1.8 is not supported).

## Authors
  * Dmitry Afanasyev (dimarzio1986@gmail.com), please do not hesitate to contact me if you have any questions or suggestions.

This project rocks and uses MIT-LICENSE.
