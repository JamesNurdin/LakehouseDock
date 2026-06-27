WITH post_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        t.id                     AS tag_id,
        t.name                   AS tag_name,
        pl.person_id             AS liker_id
    FROM post p
    JOIN post_has_tag_tag pt ON p.id = pt.post_id
    JOIN tag t               ON pt.tag_id = t.id
    JOIN tag_class tc        ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_post pl ON p.id = pl.post_id
    WHERE p.length > 100
      AND tc.name = 'Technology'
),

tag_like_counts AS (
    SELECT
        forum_id,
        tag_id,
        tag_name,
        COUNT(DISTINCT liker_id) AS like_count
    FROM post_likes
    GROUP BY forum_id, tag_id, tag_name
),

ranked_tags AS (
    SELECT
        forum_id,
        tag_id,
        tag_name,
        like_count,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY like_count DESC) AS tag_rank
    FROM tag_like_counts
)
SELECT
    f.id        AS forum_id,
    f.title     AS forum_title,
    rt.tag_id,
    rt.tag_name,
    rt.like_count,
    rt.tag_rank
FROM ranked_tags rt
JOIN forum f ON rt.forum_id = f.id
WHERE rt.tag_rank <= 3
ORDER BY f.id, rt.tag_rank
