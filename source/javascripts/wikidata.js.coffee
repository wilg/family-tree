extend = (object, properties) ->
  for key, val of properties
    object[key] = val
  object

merge = (options, overrides) ->
  extend (extend {}, options), overrides

window.wikidataIdentityMap = []

class Wikidata

  cachedEntity: (id) ->
    window.wikidataIdentityMap[id]

  fetchEntities: (query, callback = null) ->
    query = merge({
      action: 'wbgetentities'
      sites: 'enwiki'
      format: 'json'
    }, query)

    $.ajax({
      dataType: "jsonp",
      url: "http://www.wikidata.org/w/api.php?#{$.param(query)}",
      }).done (root) ->
        entities = []
        entities.push(new WikidataEntity(value)) for key, value of root['entities']
        callback(entities) if callback

  fetchEntitiesByTitle: (titles, callback = null) ->
    @fetchEntities({titles: titles.join('|')}, callback)

  fetchEntitiesByIds: (ids, callback = null) ->
    @fetchEntities({ids: ids.join('|')}, callback)

class WikidataEntity

  @propertyPresets = {
    mother:   "P25",
    father:   "P22",
    children: "P40",
    doctoral_advisor: "P184"
  }

  constructor: (@hash) ->
    window.wikidataIdentityMap[@hash.id] = @

  claimsForPropertyId: (propertyId) ->
    @hash.claims[propertyId]

  fetchEntitiesForProperty: (preset, callback) ->
    fetchEntitiesForPropertyId @propertyPresets[preset], callback

  fetchEntitiesForPropertyId: (propertyId, callback) ->
    ids = []
    for claim in @hash.claims[propertyId]
      if claim.mainsnak.datavalue.type is 'wikibase-entityid'
        ids.push "Q#{claim.mainsnak.datavalue.value['numeric_id']}"
    new Wikidata().fetchEntitiesById(ids, callback)


window.Wikidata = Wikidata