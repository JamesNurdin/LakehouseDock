WITH comments_by_forum_tag AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_commenters
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    JOIN forum f
        ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    JOIN tag t
        ON pt.tag_id = t.id
    JOIN person per
        ON c.creator_person_id = per.id
    WHERE per.gender = 'male'
      AND t.name LIKE 'sports%'
    GROUP BY f.id, f.title, t.id, t.name
)
SELECT
    forum_id,
    forum_title,
    tag_name,
    comment_count,
    avg_comment_length,
    distinct_commenters
FROM comments_by_forum_tag
ORDER BY comment_count DESC
LIMIT 10
