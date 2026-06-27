-- Top 5 tags per forum by total likes, with comment statistics
WITH forum_tag_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(plp.person_id) AS total_likes,
        COUNT(DISTINCT c.id) AS total_comments,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT pl.id) AS distinct_comment_countries
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN person_likes_post plp
        ON plp.post_id = p.id
    JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    JOIN tag t
        ON pht.tag_id = t.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN place pl
        ON c.location_country_id = pl.id
    GROUP BY f.id, f.title, t.id, t.name
),
ranked_tags AS (
    SELECT
        forum_id,
        forum_title,
        tag_id,
        tag_name,
        total_likes,
        total_comments,
        avg_comment_length,
        distinct_comment_countries,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY total_likes DESC) AS tag_rank
    FROM forum_tag_stats
)
SELECT
    forum_id,
    forum_title,
    tag_id,
    tag_name,
    total_likes,
    total_comments,
    avg_comment_length,
    distinct_comment_countries,
    tag_rank
FROM ranked_tags
WHERE tag_rank <= 5
ORDER BY forum_id, tag_rank
