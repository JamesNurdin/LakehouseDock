WITH post_tag_join AS (
    SELECT
        p.id AS post_id,
        p.creation_date AS post_creation_date,
        p.length,
        p.creator_person_id,
        p.container_forum_id,
        pt.tag_id,
        pt.creation_date AS tag_creation_date
    FROM post AS p
    JOIN post_has_tag_tag AS pt
        ON pt.post_id = p.id
)
SELECT
    tag_id,
    COUNT(DISTINCT post_id) AS post_count,
    AVG(length) AS avg_post_length,
    MIN(post_creation_date) AS earliest_post_date,
    MAX(post_creation_date) AS latest_post_date,
    COUNT(DISTINCT creator_person_id) AS distinct_creators
FROM post_tag_join
GROUP BY tag_id
ORDER BY post_count DESC
LIMIT 10
