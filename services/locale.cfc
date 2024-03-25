component extends="baseService" {
  function getLocaleByCode(code) {
    return entityLoad( 'locale', { deleted: false } ).filter( (locale) => locale.getCode() == code )?.first();
  }
}