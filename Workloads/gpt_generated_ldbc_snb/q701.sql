SELECT
    p1.id,
    p1.first_name,
    p1.last_name,
    p1.gender,
    p1.location_city_id,
    SUM(CASE WHEN p2.gender = 'male'   THEN 1 ELSE 0 END) AS male_friends,
    SUM(CASE WHEN p2.gender = 'female' THEN 1 ELSE 0 END) AS female_friends,
    COUNT(*)                                             AS total_friends
FROM person_knows_person pkp
JOIN person p1
  ON pkp.person1_id = p1.id               -- person who knows
JOIN person p2
  ON pkp.person2_id = p2.id               -- person being known
GROUP BY
    p1.id,
    p1.first_name,
    p1.last_name,
    p1.gender,
    p1.location_city_id
ORDER BY total_friends DESC
LIMIT 100
