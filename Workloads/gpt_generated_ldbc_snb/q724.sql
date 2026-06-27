WITH post_like_counts AS (
    SELECT
        post_id,
        COUNT(*) AS like_count
    FROM person_likes_post
    GROUP BY post_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(pl.like_count), 0) AS post_like_count
    FROM post p
    LEFT JOIN post_like_counts pl ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
member_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
tag_usage AS (
    SELECT
        f.id AS forum_id,
        t.name AS tag_name,
        COUNT(*) AS tag_usage
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    JOIN tag t ON t.id = pht.tag_id
    GROUP BY f.id, t.name
),
top_tag AS (
    SELECT
        forum_id,
        tag_name,
        tag_usage,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_usage DESC) AS rn
    FROM tag_usage
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.post_like_count, 0) AS post_like_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    tt.tag_name AS top_tag,
    tt.tag_usage AS top_tag_usage
FROM forum f
LEFT JOIN member_counts mc ON mc.forum_id = f.id
LEFT JOIN post_stats ps ON ps.forum_id = f.id
LEFT JOIN comment_stats cs ON cs.forum_id = f.id
LEFT JOIN top_tag tt ON tt.forum_id = f.id AND tt.rn = 1
ORDER BY ps.post_count DESC
LIMIT 20
