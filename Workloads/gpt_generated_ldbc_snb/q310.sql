WITH forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title
    FROM forum f
),
member_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
post_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count
    FROM post p
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_tag_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT pt.tag_id) AS distinct_post_tag_count
    FROM post p
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_tag_metrics AS (
    SELECT
        ft.forum_id,
        COUNT(DISTINCT ft.tag_id) AS distinct_forum_tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
)
SELECT
    fb.forum_id,
    fb.title,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.avg_post_length, 0) AS avg_post_length,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(ptm.distinct_post_tag_count, 0) AS distinct_post_tag_count,
    COALESCE(ftm.distinct_forum_tag_count, 0) AS distinct_forum_tag_count
FROM forum_base fb
LEFT JOIN member_counts mc ON mc.forum_id = fb.forum_id
LEFT JOIN post_metrics pm ON pm.forum_id = fb.forum_id
LEFT JOIN comment_metrics cm ON cm.forum_id = fb.forum_id
LEFT JOIN post_tag_metrics ptm ON ptm.forum_id = fb.forum_id
LEFT JOIN forum_tag_metrics ftm ON ftm.forum_id = fb.forum_id
ORDER BY member_count DESC, post_count DESC
LIMIT 10
