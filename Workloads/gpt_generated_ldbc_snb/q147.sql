WITH post_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.length) AS total_post_length,
        COALESCE(SUM(pl.like_cnt), 0) AS total_post_likes
    FROM post p
    LEFT JOIN (
        SELECT plp.post_id, COUNT(*) AS like_cnt
        FROM person_likes_post plp
        GROUP BY plp.post_id
    ) pl ON p.id = pl.post_id
    GROUP BY p.container_forum_id
),
comment_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COALESCE(SUM(cl.like_cnt), 0) AS total_comment_likes
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    LEFT JOIN (
        SELECT plc.comment_id, COUNT(*) AS like_cnt
        FROM person_likes_comment plc
        GROUP BY plc.comment_id
    ) cl ON c.id = cl.comment_id
    GROUP BY p.container_forum_id
),
member_metrics AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
tag_metrics AS (
    SELECT
        ft.forum_id,
        COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),
forum_info AS (
    SELECT
        f.id,
        f.title,
        f.creation_date,
        f.moderator_person_id
    FROM forum f
)
SELECT
    fi.id AS forum_id,
    fi.title,
    fi.creation_date,
    pm.post_count,
    pm.total_post_length,
    pm.total_post_likes,
    cm.comment_count,
    cm.avg_comment_length,
    cm.total_comment_likes,
    mm.member_count,
    tm.tag_count,
    CONCAT(moderator.first_name, ' ', moderator.last_name) AS moderator_name
FROM forum_info fi
LEFT JOIN post_metrics pm ON fi.id = pm.forum_id
LEFT JOIN comment_metrics cm ON fi.id = cm.forum_id
LEFT JOIN member_metrics mm ON fi.id = mm.forum_id
LEFT JOIN tag_metrics tm ON fi.id = tm.forum_id
LEFT JOIN person moderator ON fi.moderator_person_id = moderator.id
ORDER BY pm.post_count DESC NULLS LAST
LIMIT 20
