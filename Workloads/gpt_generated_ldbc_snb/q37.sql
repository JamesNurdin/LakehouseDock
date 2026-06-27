WITH member_details AS (
    SELECT
        fhmp.forum_id,
        p.id AS person_id,
        p.gender,
        city.id AS city_id,
        city.name AS city_name,
        region.id AS region_id,
        region.name AS region_name,
        pwc.company_id,
        comp.name AS company_name,
        comp_loc.id AS comp_loc_id,
        comp_loc.name AS comp_loc_name,
        comp_region.id AS comp_region_id,
        comp_region.name AS comp_region_name,
        psu.university_id,
        uni.name AS university_name,
        uni_loc.id AS uni_loc_id,
        uni_loc.name AS uni_loc_name,
        uni_region.id AS uni_region_id,
        uni_region.name AS uni_region_name
    FROM forum_has_member_person fhmp
    JOIN person p ON fhmp.person_id = p.id
    JOIN place city ON p.location_city_id = city.id
    LEFT JOIN place region ON city.part_of_place_id = region.id
    LEFT JOIN person_work_at_company pwc ON p.id = pwc.person_id
    LEFT JOIN organisation comp ON pwc.company_id = comp.id
    LEFT JOIN place comp_loc ON comp.location_place_id = comp_loc.id
    LEFT JOIN place comp_region ON comp_loc.part_of_place_id = comp_region.id
    LEFT JOIN person_study_at_university psu ON p.id = psu.person_id
    LEFT JOIN organisation uni ON psu.university_id = uni.id
    LEFT JOIN place uni_loc ON uni.location_place_id = uni_loc.id
    LEFT JOIN place uni_region ON uni_loc.part_of_place_id = uni_region.id
)
SELECT
    forum_id,
    COUNT(DISTINCT person_id) AS total_members,
    COUNT(DISTINCT CASE WHEN gender = 'male' THEN person_id END) AS male_members,
    COUNT(DISTINCT CASE WHEN gender = 'female' THEN person_id END) AS female_members,
    COUNT(DISTINCT company_id) AS distinct_companies,
    COUNT(DISTINCT university_id) AS distinct_universities,
    COUNT(DISTINCT region_id) AS distinct_residence_regions,
    COUNT(DISTINCT comp_region_id) AS distinct_work_regions,
    COUNT(DISTINCT uni_region_id) AS distinct_study_regions
FROM member_details
GROUP BY forum_id
ORDER BY total_members DESC
LIMIT 10
