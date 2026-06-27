WITH city_comments AS (
    SELECT
        city.id AS city_id,
        city.name AS city_name,
        c.id AS comment_id,
        c.length AS comment_length,
        p.id AS person_id,
        ct.tag_id AS tag_id,
        plc.person_id AS liked_by_person_id
    FROM person p
    JOIN place city ON p.location_city_id = city.id
    JOIN comment c ON c.creator_person_id = p.id
    LEFT JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    WHERE city.type = 'City'
),
city_agg AS (
    SELECT
        city_id,
        city_name,
        count(DISTINCT comment_id) AS total_comments,
        count(DISTINCT person_id) AS distinct_commenters,
        avg(comment_length) AS avg_comment_length,
        count(liked_by_person_id) AS total_likes
    FROM city_comments
    GROUP BY city_id, city_name
),
tag_counts AS (
    SELECT
        city_id,
        tag_id,
        count(*) AS tag_cnt
    FROM city_comments
    WHERE tag_id IS NOT NULL
    GROUP BY city_id, tag_id
),
top_tags AS (
    SELECT
        city_id,
        tag_id AS top_tag_id,
        tag_cnt,
        row_number() OVER (PARTITION BY city_id ORDER BY tag_cnt DESC) AS rn
    FROM tag_counts
)
SELECT
    ca.city_id,
    ca.city_name,
    ca.total_comments,
    ca.distinct_commenters,
    ca.avg_comment_length,
    ca.total_likes,
    tt.top_tag_id
FROM city_agg ca
LEFT JOIN (
    SELECT city_id, top_tag_id
    FROM top_tags
    WHERE rn = 1
) tt ON ca.city_id = tt.city_id
ORDER BY ca.total_comments DESC
LIMIT 10
