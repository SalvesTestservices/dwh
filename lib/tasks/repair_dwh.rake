namespace :dwh do
  task repair_dwh: :environment do
   
  end
end

=begin

In DWH heb je nu een record, bv dim_user met een id en original_id.
In Synergy is deze user straks gemigreerd met een nieuwe id en op een bepaald textfield de original_id.
Het record kan worden gevonden op basis van de original_id die uit synergy mee komt.
Het old_original_id is de oude original_id die in het DWH staat.
De repair task moet in het DWH de original_id vervangen door de nieuwe id.
De old_source wordt bepaald ahv van het account.
En refreshed op true zetten.
Hierdoor verwijst het record naar het juiste record in Synergy en niet meer naar Backbone of oude Synergy.
Op basis van refreshed kun je bepalen of de record gemigreerd is en of er records in het DWH zijn die niet meer bestaan in de nieuwe Synergy.

Voor migratie

ID    ORIGINAL_ID   OLD_ORIGINAL_ID   OLD_SOURCE           REFRESHED
123   456                                                  false

Na migratie, nieuwe record is 729, freetextfield is 456

ID    ORIGINAL_ID   OLD_ORIGINAL_ID   OLD_SOURCE           REFRESHED
123   729           456               backbone/synergy     true


dim_customers is anders, omdat deze ook wordt ontdubbeld.
Hiervoor komt een excel sheet met daarin ook de original_id van ontdubbelde customer voor de niet meer bestaande customers.
Hierdoor kunnen deze customers worden gevonden en de original_id worden vervangen door de nieuwe id.
En daardoor ook de projecten etc aan de ontdubbelde customer worden gehangen.

=end