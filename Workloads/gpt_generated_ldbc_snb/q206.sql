-- Top 20 persons with the most connections, showing average friend age and friend‑city diversity
WITH edge AS (
    SELECT person1_id AS person_id,
           person2_id AS friend_id,
           creation_date
    FROM person_knows_person
    UNION ALL
    SELECT person2_id AS person_id,
           person1_id AS friend_id,
           creation_date
    FROM person_knows_person
),
friend_details AS (
    SELECT e.person_id,
           e.friend_id,
           p.gender AS friend_gender,
           CAST(p.birthday AS DATE) AS friend_birthdate,
           p.location_city_id AS friend_city_id
    FROM edge e
    JOIN person p
      ON p.id = e.friend_id
),
person_summary AS (
    SELECT per.id,
           per.gender,
           per.location_city_id,
           COUNT(fd.friend_id) AS num_friends,
           AVG(date_diff('year', fd.friend_birthdate, current_date)) AS avg_friend_age,
           COUNT(DISTINCT fd.friend_city_id) AS friend_cities
    FROM person per
    LEFT JOIN friend_details fd
      ON fd.person_id = per.id
    GROUP BY per.id, per.gender, per.location_city_id
)
SELECT id,
       gender,
       location_city_id,
       num_friends,
       avg_friend_age,
       friend_cities
FROM person_summary
ORDER BY num_friends DESC
LIMIT 20
