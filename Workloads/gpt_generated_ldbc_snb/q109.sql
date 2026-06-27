WITH connections AS (
    SELECT
        kp.person1_id AS person_id,
        p2.gender AS friend_gender,
        p2.location_city_id AS friend_city_id
    FROM person_knows_person kp
    JOIN person p1
      ON kp.person1_id = p1.id
    JOIN person p2
      ON kp.person2_id = p2.id
),
connections_rev AS (
    SELECT
        kp.person2_id AS person_id,
        p1.gender AS friend_gender,
        p1.location_city_id AS friend_city_id
    FROM person_knows_person kp
    JOIN person p1
      ON kp.person1_id = p1.id
    JOIN person p2
      ON kp.person2_id = p2.id
),
all_connections AS (
    SELECT person_id, friend_gender, friend_city_id FROM connections
    UNION ALL
    SELECT person_id, friend_gender, friend_city_id FROM connections_rev
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    COUNT(ac.friend_gender) AS total_friends,
    COUNT(CASE WHEN ac.friend_gender = 'male' THEN 1 END) AS male_friends,
    COUNT(CASE WHEN ac.friend_gender = 'female' THEN 1 END) AS female_friends,
    COUNT(DISTINCT ac.friend_city_id) AS distinct_friend_cities
FROM person p
LEFT JOIN all_connections ac
  ON ac.person_id = p.id
GROUP BY
    p.id,
    p.first_name,
    p.last_name,
    p.gender
ORDER BY total_friends DESC
LIMIT 100
