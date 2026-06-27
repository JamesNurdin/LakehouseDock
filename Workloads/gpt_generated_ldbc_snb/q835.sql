WITH gender_friendships AS (
    SELECT p1.gender AS gender1,
           p2.gender AS gender2,
           COUNT(*) AS friendship_count
    FROM person_knows_person pkp
    JOIN person p1
      ON pkp.person1_id = p1.id
    JOIN person p2
      ON pkp.person2_id = p2.id
    GROUP BY p1.gender, p2.gender
)
SELECT gender1,
       gender2,
       friendship_count
FROM gender_friendships
ORDER BY friendship_count DESC
