module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/components/**/*.erb'
  ],
  safelist: [
    'bg-white/10',
    'backdrop-blur-md',
    'rounded-3xl',
    'shadow-xl',
    'border-white/20',
    'text-white',
    'bg-gradient-to-br',
    'from-indigo-500',
    'via-blue-600',
    'to-purple-600'
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
