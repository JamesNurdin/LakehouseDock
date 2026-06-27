WITH
    forum_base AS (
        SELECT
            f.id AS forum_id,
            f.title,
            mod.first_name AS moderator_first_name,
            mod.last_name  AS moderator_last_name
        FROM forum f
        LEFT JOIN person mod
            ON f.moderator_person_id = mod.id
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
    post_metrics AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT p.id)   AS post_count,
            AVG(p.length)          AS avg_post_length
        FROM post p
        GROUP BY p.container_forum_id
    ),
    comment_metrics AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT c.id)   AS comment_count,
            AVG(c.length)          AS avg_comment_length
        FROM comment c
        JOIN post p
            ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    )
SELECT
    fb.forum_id,
    fb.title,
    fb.moderator_first_name,
    fb.moderator_last_name,
    COALESCE(mc.member_count, 0)   AS member_count,
    COALESCE(tc.tag_count, 0)      AS tag_count,
    COALESCE(pm.post_count, 0)     AS post_count,
    pm.avg_post_length,
    COALESCE(cm.comment_count, 0)  AS comment_count,
    cm.avg_comment_length
FROM forum_base fb
LEFT JOIN member_counts mc
    ON mc.forum_id = fb.forum_id
LEFT JOIN tag_counts tc
    ON tc.forum_id = fb.forum_id
LEFT JOIN post_metrics pm
    ON pm.forum_id = fb.forum_id
LEFT JOIN comment_metrics cm
    ON cm.forum_id = fb.forum_id
ORDER BY member_count DESC
LIMIT 10
