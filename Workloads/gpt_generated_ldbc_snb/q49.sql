WITH person_comments AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name,
        pl.name AS city_name,
        c.id AS comment_id,
        c.length AS comment_length,
        po.id AS post_id
    FROM comment c
    JOIN person p
        ON c.creator_person_id = p.id
    JOIN place pl
        ON p.location_city_id = pl.id
    LEFT JOIN post po
        ON c.parent_post_id = po.id
)
SELECT
    person_id,
    first_name,
    last_name,
    city_name,
    COUNT(comment_id) AS comment_count,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT post_id) AS distinct_posts_commented
FROM person_comments
GROUP BY person_id, first_name, last_name, city_name
ORDER BY comment_count DESC
LIMIT 10
