const { environment } = require('@rails/webpacker')

// Remove o exclude padrão que ignora node_modules
const babelLoader = environment.loaders.get('babel')
const babelLoaderConfig = babelLoader.use.find(el => el.loader === 'babel-loader')

// Substitui o exclude ignorando tudo do node_modules, exceto @hotwired/turbo
babelLoaderConfig.options.exclude = modulePath => {
  return (
    /node_modules/.test(modulePath) &&
    !/node_modules\/@hotwired\/turbo/.test(modulePath)
  )
}

module.exports = environment
