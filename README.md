# Rumblelog

A sample blog application backed by the [Fauna cloud database](http://fauna.org).

## How to deploy your own Rumbleog to Heroku

Clone either the original project or your fork of the project, the commands we show you assume you're in the root of the project directory.

### Fauna

[Create a Fauna account](http://fauna.org/)

[Create a Database](https://fauna.org/account/databases), name it anything at all.

At the database page in fauna, create a new class named `Pages` (capitalization is important).
Copy the `Server Key`, we'll need it later.

### Signup for Heroku

[Sign up for Heroku](http://heroku.com) and follow along with the [QuickStart Guide](https://devcenter.heroku.com/articles/getting-started-with-ruby)
Get the [Heroku Toolbelt](https://toolbelt.heroku.com/)

Login to Heroku: `heroku login`

Pick a unique name for your blog: call it my-fauna-blog: `heroku create my-fauna-blog`

Create the heroku config vars

* `heroku config:set RUMBLELOG_ADMIN_USERNAME=` is the username for creating new posts.
* `heroku config:set RUMBLELOG_ADMIN_PASSWORD=` is the password for creating new posts.
* `heroku config:set RUMBLELOG_FAUNA_SECRET=` is your Server Key from the fauna database page


Deploy! `git push heroku master`
