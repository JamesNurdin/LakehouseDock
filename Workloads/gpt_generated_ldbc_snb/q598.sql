WITH post_metrics AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        COUNT(DISTINCT p.id) AS post_cnt,
        COUNT(DISTINCT pl.person_id) AS distinct_likers_cnt,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators_cnt
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    JOIN post p ON p.id = pht.post_id
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY t.id, t.name, tc.name
),
comment_metrics AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        COUNT(DISTINCT c.id) AS comment_cnt,
        COUNT(DISTINCT c.creator_person_id) AS distinct_commenters_cnt
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    JOIN comment c ON c.id = cht.comment_id
    GROUP BY t.id, t.name, tc.name
)
SELECT
    COALESCE(pm.tag_id, cm.tag_id) AS tag_id,
    COALESCE(pm.tag_name, cm.tag_name) AS tag_name,
    COALESCE(pm.tag_class_name, cm.tag_class_name) AS tag_class_name,
    COALESCE(pm.post_cnt, 0) AS post_cnt,
    COALESCE(cm.comment_cnt, 0) AS comment_cnt,
    COALESCE(pm.distinct_likers_cnt, 0) AS distinct_likers_cnt,
    COALESCE(pm.distinct_post_creators_cnt, 0) AS distinct_post_creators_cnt,
    COALESCE(cm.distinct_commenters_cnt, 0) AS distinct_commenters_cnt,
    (COALESCE(pm.post_cnt, 0) + COALESCE(cm.comment_cnt, 0)) AS total_content_cnt
FROM post_metrics pm
FULL OUTER JOIN comment_metrics cm ON cm.tag_id = pm.tag_id
ORDER BY total_content_cnt DESC
LIMIT 10
