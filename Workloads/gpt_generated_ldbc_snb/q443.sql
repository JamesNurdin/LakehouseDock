WITH forum_base AS (
    SELECT 
        f.id AS forum_id,
        f.title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
),
post_stats AS (
    SELECT 
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT 
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
member_stats AS (
    SELECT 
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_tag_stats AS (
    SELECT 
        ft.forum_id,
        COUNT(DISTINCT ft.tag_id) AS forum_tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),
post_tag_stats AS (
    SELECT 
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT pt.tag_id) AS post_tag_count
    FROM post_has_tag_tag pt
    JOIN post p
        ON pt.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_tag_stats AS (
    SELECT 
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT ct.tag_id) AS comment_tag_count
    FROM comment_has_tag_tag ct
    JOIN comment c
        ON ct.comment_id = c.id
    JOIN post p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_like_stats AS (
    SELECT 
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT pl.person_id) AS post_like_user_count
    FROM person_likes_post pl
    JOIN post p
        ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_like_stats AS (
    SELECT 
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT cl.person_id) AS comment_like_user_count
    FROM person_likes_comment cl
    JOIN comment c
        ON cl.comment_id = c.id
    JOIN post p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT 
    fb.forum_id,
    fb.title,
    fb.moderator_first_name,
    fb.moderator_last_name,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ms.member_count, 0) AS member_count,
    COALESCE(fts.forum_tag_count, 0) AS forum_tag_count,
    COALESCE(pts.post_tag_count, 0) AS post_tag_count,
    COALESCE(cts.comment_tag_count, 0) AS comment_tag_count,
    COALESCE(pls.post_like_user_count, 0) AS post_like_user_count,
    COALESCE(cls.comment_like_user_count, 0) AS comment_like_user_count
FROM forum_base fb
LEFT JOIN post_stats ps
    ON fb.forum_id = ps.forum_id
LEFT JOIN comment_stats cs
    ON fb.forum_id = cs.forum_id
LEFT JOIN member_stats ms
    ON fb.forum_id = ms.forum_id
LEFT JOIN forum_tag_stats fts
    ON fb.forum_id = fts.forum_id
LEFT JOIN post_tag_stats pts
    ON fb.forum_id = pts.forum_id
LEFT JOIN comment_tag_stats cts
    ON fb.forum_id = cts.forum_id
LEFT JOIN post_like_stats pls
    ON fb.forum_id = pls.forum_id
LEFT JOIN comment_like_stats cls
    ON fb.forum_id = cls.forum_id
ORDER BY post_count DESC
LIMIT 20
