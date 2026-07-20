select * from seedlot where seedlot_number = '62505';

--spar.seedlot_orchard
select orchard_id from seedlot where seedlot_number = '62505' and orchard_id is not null
union
select secondary_orchard_id from seedlot where seedlot_number = '62505' and secondary_orchard_id is not null;

--spar.seedlot_collection_method
select cone_collection_method_code from seedlot where seedlot_number = '62505' and cone_collection_method_code is not null
union
select cone_collection_method2_code from seedlot where seedlot_number = '62505' and cone_collection_method2_code is not null;

select * from seedlot_plan_zone where seedlot_number = '62505';
select * from seedlot_genetic_worth where seedlot_number = '62505';
select * from seedlot_owner_quantity where seedlot_number = '62505';
select * from seedlot_parent_tree where seedlot_number = '62505';
select * from seedlot_parent_tree_gen_qlty where seedlot_number = '62505';
select * from seedlot_parent_tree_smp_mix where seedlot_number = '62505';
select * from smp_mix where seedlot_number = '62505';
select * from smp_mix_gen_qlty where seedlot_number = '62505';
