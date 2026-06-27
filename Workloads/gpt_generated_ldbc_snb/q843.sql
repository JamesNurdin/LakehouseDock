WITH post_tags AS (
    SELECT
        p.id AS post_id,
        p.container_forum_id AS forum_id,
        p.creation_date AS post_creation_date,
        p.length AS post_length,
        p.language AS post_language,
        COUNT(DISTINCT pt.tag_id) AS tag_count
    FROM post p
    LEFT JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    GROUP BY p.id, p.container_forum_id, p.creation_date, p.length, p.language
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    COUNT(pt.post_id) AS total_posts,
    AVG(pt.post_length) AS avg_post_length,
    SUM(pt.tag_count) AS total_tags_used,
    AVG(pt.tag_count) AS avg_tags_per_post,
    COUNT(DISTINCT pt.post_language) AS distinct_languages
FROM forum f
JOIN post_tags pt
    ON pt.forum_id = f.id
GROUP BY f.id, f.title, f.creation_date
ORDER BY total_posts DESC
LIMIT 10
