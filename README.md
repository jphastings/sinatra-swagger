# Sinatra::Swagger

Extensions & helper methods for accesing your swagger documentation from within your sinatra routes.

This library is in the *very* early stages of development, there will be 'obvious' features that are missing and wild inefficiencies, but please feel free to file issues/enhancements if there's anything you think would be useful.

## Param Validator

This extension will use the `parameters` component of the route being accessed from your Swagger document to type cast your incoming parameters and raise `400` errors if any are incorrect:

### An example

Your swagger 2.0 documentation, in the root of your project at `swagger/search.yaml`, might have some of these components:

```yaml
swagger: 2.0
paths:
  /search/{type}:
    get:
      parameters:
        - name: type
          in: path
          description: Type of object to search for
          required: true
        - name: q
          in: query
          type: string
          required: true
        - name: limit
          in: query
          type: integer
          minimum: 1
          required: false
          default: 20
```

You would load that in your sinatra application like this:

```ruby
require "sinatra/base"
require "sinatra/swagger"

class Search < Sinatra::Base
  register Sinatra::Swagger::ParamValidator
  swagger "swagger/search.yaml"

  get "/search/*" do
    # Sinatra::Swagger has pulled out the 'type' from the path
    search_type = params['type']
    # Sinatra::Swagger has ensured limit is integer-like, is one or bigger, and will be set to 20 if not given by the user
    limit = params['limit']

    swagger_spec # => is the hash from the spec at `paths./search/{type}.get`
  end
end
```

For now, if you were to request `/search/books?limit=p` then a `before` hook would catch the error and return a `400` with a JSON description of the issue.

```json
{
  "error": "invalid_params",
  "developerMessage": "Some of the given parameters were invalid according to the Swagger spec.",
  "details": {
    "invalidities": {
        "limit": "incorrect_type",
        "q": "missing"
    }
  }
}
```

You can override what happens when an invalidity is encountered by overriding the helper method `invalid_params` which takes a hash of invalidities in the form `param_name => issue_description_as_symbol`.

## Spec Enforcer

While you're developing it can be really helpful to know that the output of your endpoints matches your spec. The spec enforcer will raise an exception if the data you're sending to the user doesn't conform to your swagger declared schema (if there is one).

Your Swagger 2.0 doc at `swagger/shows.yaml` might have some bits that look like this:

```yaml
swagger: 2.0
paths:
  /shows/{showId}:
    responses:
      200:
        schema:
          title: Details describing a post
          type: object
          required:
            - name
          additionalProperties: false
          properties:
            name:
              type: string
```

You could reference it like this:

```ruby
require "sinatra/base"
require "sinatra/swagger"

class Search < Sinatra::Base
  register Sinatra::Swagger::SpecEnforcer unless production?
  swagger "swagger/shows.yaml"

  get "/shows/*" do
    {
      title: "This isn't a schema-valid response"
    }.to_json
  end
end
```

The `after` hook will check the response body and will run the schema validation and raise a `JSON::Schema::ValidationError` exception as the output doesn't match the schema.

In order to not be restrictive, if the output doesn't look like JSON or if there's no schema defined, then no action will be taken and the body will be sent to the client.