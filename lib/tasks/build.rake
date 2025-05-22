# ref: https://github.com/rails/rails/issues/43906#issuecomment-1094380699
# https://github.com/rails/rails/issues/43906#issuecomment-1099992310
task before_assets_precompile: :environment do
  # run a command which starts your packaging
  system('pnpm install')
  system('echo "-------------- Bulding SDK for Production --------------"')
  system('pnpm run build:sdk')
  system('echo "-------------- Bulding App for Production --------------"')
end

# Task to ensure all image paths are properly created
task ensure_image_paths: :environment do
  system('echo "-------------- Ensuring Image Paths Exist --------------"')
  system('mkdir -p public/assets/images')
  system('mkdir -p app/assets/builds/images')
  system('mkdir -p public/packs/images')
  # Copy app images to ensure they're available in multiple paths
  system('cp -r app/javascript/dashboard/assets/images/* public/assets/images/ 2>/dev/null || :')
  system('cp -r app/javascript/shared/assets/images/* public/assets/images/ 2>/dev/null || :')
  system('cp -r app/javascript/widget/assets/images/* public/assets/images/ 2>/dev/null || :')
  system('echo "-------------- Image Paths Created --------------"')
end

# every time you execute 'rake assets:precompile'
# run 'before_assets_precompile' first
Rake::Task['assets:precompile'].enhance %w[before_assets_precompile ensure_image_paths]
