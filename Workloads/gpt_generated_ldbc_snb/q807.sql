WITH post_likes AS (
    SELECT
        p.id AS post_id,
        p.container_forum_id AS forum_id,
        f.title AS forum_title,
        p.length AS post_length,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(pl.person_id) AS like_cnt
    FROM post p
    JOIN forum f
        ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    JOIN tag t
        ON pt.tag_id = t.id
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY
        p.id,
        p.container_forum_id,
        f.title,
        p.length,
        t.id,
        t.name
),
forum_tag_agg AS (
    SELECT
        forum_id,
        forum_title,
        tag_id,
        tag_name,
        SUM(like_cnt) AS total_likes,
        COUNT(DISTINCT post_id) AS post_count,
        AVG(post_length) AS avg_post_length
    FROM post_likes
    GROUP BY
        forum_id,
        forum_title,
        tag_id,
        tag_name
),
ranked_tags AS (
    SELECT
        forum_id,
        forum_title,
        tag_id,
        tag_name,
        total_likes,
        post_count,
        avg_post_length,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY total_likes DESC) AS rn
    FROM forum_tag_agg
)
SELECT
    forum_id,
    forum_title,
    tag_id,
    tag_name,
    total_likes,
    post_count,
    avg_post_length
FROM ranked_tags
WHERE rn <= 3
ORDER BY forum_id, total_likes DESC
