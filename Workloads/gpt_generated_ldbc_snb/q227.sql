-- Top‑3 tags per forum (by distinct post count) together with the total likes and comments for those posts
WITH forum_tag_stats AS (
    SELECT
        f.id   AS forum_id,
        f.title AS forum_title,
        t.id   AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT p.id)               AS post_cnt,
        COUNT(DISTINCT plp.person_id)      AS like_cnt,
        COUNT(DISTINCT c.id)               AS comment_cnt
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    LEFT JOIN tag t
        ON t.id = pht.tag_id
    GROUP BY f.id, f.title, t.id, t.name
),
ranked_tags AS (
    SELECT
        forum_id,
        forum_title,
        tag_id,
        tag_name,
        post_cnt,
        like_cnt,
        comment_cnt,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY post_cnt DESC) AS tag_rank
    FROM forum_tag_stats
)
SELECT
    forum_id,
    forum_title,
    tag_id,
    tag_name,
    post_cnt,
    like_cnt,
    comment_cnt
FROM ranked_tags
WHERE tag_rank <= 3
ORDER BY forum_id, tag_rank
