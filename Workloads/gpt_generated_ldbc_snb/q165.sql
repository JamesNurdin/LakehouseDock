WITH post_metrics AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM tag t
    JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    JOIN post p ON p.id = pht.post_id
    GROUP BY t.id
),
post_like_metrics AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT pl.person_id) AS post_like_user_count
    FROM tag t
    JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    JOIN post p ON p.id = pht.post_id
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY t.id
),
comment_metrics AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM tag t
    JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    JOIN comment c ON c.id = cht.comment_id
    GROUP BY t.id
),
comment_like_metrics AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT cl.person_id) AS comment_like_user_count
    FROM tag t
    JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    JOIN comment c ON c.id = cht.comment_id
    JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY t.id
),
forum_metrics AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT f.id) AS forum_count
    FROM tag t
    JOIN forum_has_tag_tag fht ON fht.tag_id = t.id
    JOIN forum f ON f.id = fht.forum_id
    GROUP BY t.id
),
tag_info AS (
    SELECT
        t.id,
        t.name,
        tc.name AS tag_class_name
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
)
SELECT
    ti.id AS tag_id,
    ti.name AS tag_name,
    ti.tag_class_name,
    COALESCE(pm.post_count, 0) AS post_count,
    pm.avg_post_length,
    COALESCE(plm.post_like_user_count, 0) AS post_like_user_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    cm.avg_comment_length,
    COALESCE(clm.comment_like_user_count, 0) AS comment_like_user_count,
    COALESCE(fm.forum_count, 0) AS forum_count
FROM tag_info ti
LEFT JOIN post_metrics pm ON pm.tag_id = ti.id
LEFT JOIN post_like_metrics plm ON plm.tag_id = ti.id
LEFT JOIN comment_metrics cm ON cm.tag_id = ti.id
LEFT JOIN comment_like_metrics clm ON clm.tag_id = ti.id
LEFT JOIN forum_metrics fm ON fm.tag_id = ti.id
ORDER BY post_count DESC
LIMIT 20
