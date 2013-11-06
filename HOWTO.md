How to deploy your own Rumbelog to Heroku

Clone either the original project or your fork of the project, the commands we run assume you're in the root of the project directory.

# Create a Fauna account: http://fauna.org/

# Create a Database: https://fauna.org/account/databases, name it anything at all.
# At the database page in fauna, create a new class named `Page` (capitalization is important)
# Copy the Server Key, we'll need it later.

# Signup for Heroku: http://heroku.com, follow along at: https://devcenter.heroku.com/articles/getting-started-with-ruby
# Get the heroku tool: https://toolbelt.heroku.com/

# Login to Heroku

`heroku login`

# Pick a unique name for your blog: call it my-fauna-blog
`heroku create my-fauna-blog`

# Create the heroku config vars
`heroku config:set RUMBLELOG_ADMIN_USERNAME=` is the username for creating new posts.
`heroku config:set RUMBLELOG_ADMIN_PASSWORD=` is the password for creating new posts.
`heroku config:set RUMBLELOG_FAUNA_SECRET=` is your Server Key from the fauna database page


# Deploy to heroku

`git push heroku master`
