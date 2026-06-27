WITH post_stats AS (
    SELECT
        p.container_forum_id,
        COUNT(*) AS post_count,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id,
        COUNT(*) AS comment_count
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_like_stats AS (
    SELECT
        p.container_forum_id,
        SUM(pl.like_cnt) AS total_post_likes
    FROM (
        SELECT
            pl.post_id,
            COUNT(DISTINCT pl.person_id) AS like_cnt
        FROM person_likes_post pl
        GROUP BY pl.post_id
    ) pl
    JOIN post p ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_like_stats AS (
    SELECT
        p.container_forum_id,
        SUM(cl.like_cnt) AS total_comment_likes
    FROM (
        SELECT
            cl.comment_id,
            COUNT(DISTINCT cl.person_id) AS like_cnt
        FROM person_likes_comment cl
        GROUP BY cl.comment_id
    ) cl
    JOIN comment c ON cl.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
member_stats AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_tags AS (
    SELECT
        fht.forum_id,
        ARRAY_AGG(DISTINCT t.name) AS tag_names
    FROM forum_has_tag_tag fht
    JOIN tag t ON fht.tag_id = t.id
    GROUP BY fht.forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.total_post_length, 0) AS total_post_length,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(pls.total_post_likes, 0) AS total_post_likes,
    COALESCE(cls.total_comment_likes, 0) AS total_comment_likes,
    COALESCE(ms.member_count, 0) AS member_count,
    ft.tag_names AS forum_tags
FROM forum f
LEFT JOIN post_stats ps ON ps.container_forum_id = f.id
LEFT JOIN comment_stats cs ON cs.container_forum_id = f.id
LEFT JOIN post_like_stats pls ON pls.container_forum_id = f.id
LEFT JOIN comment_like_stats cls ON cls.container_forum_id = f.id
LEFT JOIN member_stats ms ON ms.forum_id = f.id
LEFT JOIN forum_tags ft ON ft.forum_id = f.id
ORDER BY post_count DESC
LIMIT 10
