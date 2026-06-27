WITH connections AS (
  SELECT pkp.person1_id AS person_id,
         pkp.person2_id AS friend_id
  FROM person_knows_person pkp
  UNION ALL
  SELECT pkp.person2_id AS person_id,
         pkp.person1_id AS friend_id
  FROM person_knows_person pkp
),
friend_counts AS (
  SELECT person_id,
         COUNT(DISTINCT friend_id) AS friend_cnt
  FROM connections
  GROUP BY person_id
),
city_region_gender_stats AS (
  SELECT 
    region.name AS region_name,
    city.name   AS city_name,
    p.gender,
    COUNT(DISTINCT p.id)               AS person_cnt,
    AVG(COALESCE(fc.friend_cnt, 0))    AS avg_friends,
    COUNT(DISTINCT psu.university_id) AS distinct_universities,
    AVG(psu.class_year)                AS avg_class_year
  FROM person p
  LEFT JOIN friend_counts fc ON fc.person_id = p.id
  LEFT JOIN person_study_at_university psu ON psu.person_id = p.id
  LEFT JOIN place city ON city.id = p.location_city_id
  LEFT JOIN place region ON region.id = city.part_of_place_id
  GROUP BY region.name, city.name, p.gender
)
SELECT 
  region_name,
  city_name,
  gender,
  person_cnt,
  avg_friends,
  distinct_universities,
  avg_class_year
FROM city_region_gender_stats
ORDER BY region_name, city_name, gender
