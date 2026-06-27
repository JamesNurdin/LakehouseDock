WITH friend_counts AS (
    SELECT p.id AS person_id,
           count(DISTINCT fl.friend_id) AS friend_count
    FROM person p
    LEFT JOIN (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) fl
      ON fl.person_id = p.id
    GROUP BY p.id
),
tag_counts AS (
    SELECT phit.person_id AS person_id,
           count(DISTINCT phit.tag_id) AS tag_count
    FROM person_has_interest_tag phit
    GROUP BY phit.person_id
),
like_counts AS (
    SELECT plp.person_id AS person_id,
           count(DISTINCT plp.post_id) AS liked_post_count
    FROM person_likes_post plp
    GROUP BY plp.person_id
)
SELECT p.id,
       p.first_name,
       p.last_name,
       p.gender,
       coalesce(fc.friend_count, 0)      AS friend_count,
       coalesce(tc.tag_count, 0)         AS tag_count,
       coalesce(lc.liked_post_count, 0) AS liked_post_count
FROM person p
LEFT JOIN friend_counts fc ON fc.person_id = p.id
LEFT JOIN tag_counts    tc ON tc.person_id = p.id
LEFT JOIN like_counts   lc ON lc.person_id = p.id
ORDER BY friend_count DESC, tag_count DESC
LIMIT 100
