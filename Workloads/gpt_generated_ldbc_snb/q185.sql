WITH tag_university_likes AS (
    SELECT
        pht.tag_id,
        o.id AS university_id,
        o.name AS university_name,
        p.id AS person_id,
        plp.post_id
    FROM person_has_interest_tag pht
    JOIN person p ON pht.person_id = p.id
    JOIN person_study_at_university psu ON psu.person_id = p.id
    JOIN organisation o ON psu.university_id = o.id
    LEFT JOIN person_likes_post plp ON plp.person_id = p.id
    LEFT JOIN post po ON plp.post_id = po.id
    WHERE o.type = 'university'
),
aggregated AS (
    SELECT
        tag_id,
        university_name,
        COUNT(DISTINCT person_id) AS distinct_persons,
        COUNT(*) AS total_likes,
        COUNT(DISTINCT post_id) AS distinct_posts_liked
    FROM tag_university_likes
    GROUP BY tag_id, university_name
)
SELECT
    tag_id,
    university_name,
    distinct_persons,
    total_likes,
    distinct_posts_liked,
    DENSE_RANK() OVER (PARTITION BY tag_id ORDER BY distinct_persons DESC) AS university_rank
FROM aggregated
ORDER BY tag_id, university_rank
LIMIT 100
