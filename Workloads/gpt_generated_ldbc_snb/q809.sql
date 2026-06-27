WITH forum_info AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date,
        p.first_name AS moderator_first_name,
        p.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person p ON f.moderator_person_id = p.id
),
post_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT pl.person_id) AS post_like_count
    FROM post p
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        COUNT(DISTINCT cl.person_id) AS comment_like_count
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY p.container_forum_id
),
member_agg AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
tag_agg AS (
    SELECT
        ft.forum_id,
        COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
)
SELECT
    fi.forum_id,
    fi.title,
    fi.creation_date,
    fi.moderator_first_name,
    fi.moderator_last_name,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(pa.avg_post_length, 0) AS avg_post_length,
    COALESCE(pa.post_like_count, 0) AS post_like_count,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.comment_like_count, 0) AS comment_like_count,
    COALESCE(ma.member_count, 0) AS member_count,
    COALESCE(ta.tag_count, 0) AS tag_count,
    (COALESCE(pa.post_like_count, 0) + COALESCE(ca.comment_like_count, 0)) AS total_like_count
FROM forum_info fi
LEFT JOIN post_agg pa ON pa.forum_id = fi.forum_id
LEFT JOIN comment_agg ca ON ca.forum_id = fi.forum_id
LEFT JOIN member_agg ma ON ma.forum_id = fi.forum_id
LEFT JOIN tag_agg ta ON ta.forum_id = fi.forum_id
ORDER BY total_like_count DESC, post_count DESC
