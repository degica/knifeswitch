namespace :knifeswitch do
  desc 'Generate the migrations necessary to use Knifeswitch'
  task :create_migrations do
    sh 'rails g migration CreateKnifeswitchCounters ' \
       'name:string:uniq counter:integer closetime:datetime'

    puts "Done. Don't forget to run `rake db:migrate`."
  end
end
