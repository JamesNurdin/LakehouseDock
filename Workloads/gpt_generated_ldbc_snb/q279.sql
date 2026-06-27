WITH post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),

tag_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT pt.tag_id) AS distinct_post_tag_count
    FROM post p
    LEFT JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    GROUP BY p.container_forum_id
),

member_stats AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),

like_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(plp.person_id) AS total_likes_on_posts
    FROM post p
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),

comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count
    FROM post p
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(ts.distinct_post_tag_count, 0) AS distinct_post_tag_count,
    COALESCE(ms.member_count, 0) AS member_count,
    COALESCE(ls.total_likes_on_posts, 0) AS total_likes_on_posts,
    COALESCE(cs.comment_count, 0) AS comment_count
FROM forum f
LEFT JOIN post_stats ps
    ON ps.forum_id = f.id
LEFT JOIN tag_stats ts
    ON ts.forum_id = f.id
LEFT JOIN member_stats ms
    ON ms.forum_id = f.id
LEFT JOIN like_stats ls
    ON ls.forum_id = f.id
LEFT JOIN comment_stats cs
    ON cs.forum_id = f.id
ORDER BY post_count DESC
LIMIT 10
