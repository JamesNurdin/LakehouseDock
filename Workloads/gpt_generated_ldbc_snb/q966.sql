WITH forum_info AS (
    SELECT
        f.id AS forum_id,
        f.title,
        m.first_name AS moderator_first_name,
        m.last_name AS moderator_last_name
    FROM forum f
    JOIN person m ON f.moderator_person_id = m.id
),
member_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
tag_counts AS (
    SELECT
        ft.forum_id,
        COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(c.length) AS total_comment_length,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_likes_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(plp.person_id) AS post_like_count,
        COUNT(DISTINCT plp.person_id) AS distinct_post_likers
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(plc.person_id) AS comment_like_count,
        COUNT(DISTINCT plc.person_id) AS distinct_comment_likers
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    fi.forum_id,
    fi.title,
    fi.moderator_first_name,
    fi.moderator_last_name,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(tc.tag_count, 0) AS tag_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.total_post_length, 0) AS total_post_length,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_length, 0) AS total_comment_length,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pls.post_like_count, 0) AS post_like_count,
    COALESCE(pls.distinct_post_likers, 0) AS distinct_post_likers,
    COALESCE(cls.comment_like_count, 0) AS comment_like_count,
    COALESCE(cls.distinct_comment_likers, 0) AS distinct_comment_likers,
    CASE WHEN COALESCE(ps.post_count, 0) > 0
        THEN CAST(pls.post_like_count AS double) / ps.post_count
        ELSE 0
    END AS avg_likes_per_post,
    CASE WHEN COALESCE(cs.comment_count, 0) > 0
        THEN CAST(cls.comment_like_count AS double) / cs.comment_count
        ELSE 0
    END AS avg_likes_per_comment,
    CASE WHEN (COALESCE(ps.post_count, 0) + COALESCE(cs.comment_count, 0)) > 0
        THEN CAST((pls.post_like_count + cls.comment_like_count) AS double) /
             (COALESCE(ps.post_count, 0) + COALESCE(cs.comment_count, 0))
        ELSE 0
    END AS avg_likes_per_content
FROM forum_info fi
LEFT JOIN member_counts mc ON fi.forum_id = mc.forum_id
LEFT JOIN tag_counts tc ON fi.forum_id = tc.forum_id
LEFT JOIN post_stats ps ON fi.forum_id = ps.forum_id
LEFT JOIN comment_stats cs ON fi.forum_id = cs.forum_id
LEFT JOIN post_likes_stats pls ON fi.forum_id = pls.forum_id
LEFT JOIN comment_likes_stats cls ON fi.forum_id = cls.forum_id
ORDER BY avg_likes_per_content DESC
LIMIT 10
