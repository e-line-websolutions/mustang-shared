# WebManager Documentation

## Table of Contents

1. [Getting Started](#getting-started)
2. ...
3. [Views](#views)

### Getting Started

### ...

### Views

To have a style sheet for a particualr view only, you can append the path to this style sheet to the rc.stylesheets array.

```
arrayAppend( rc.stylesheets, "/inc/css/my-page.css" );
```

## Modules

### Document Manager

whereConfig is used to filter Document Manager documents, it's a comma separated list of value pairs with a modifier (`lt`, `gt`, `eq`, `neq`, `lte`, `gte`): `whereConfig = "fieldId_modifier_value";`

For example (fieldId 123 has a value of 5):

```
whereConfig = "123_eq_5";
```

