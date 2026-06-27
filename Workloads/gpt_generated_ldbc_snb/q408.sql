WITH post_stats AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT p.id) AS post_cnt,
        AVG(p.length) AS avg_post_len,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_creator_cnt
    FROM tag_class tc
    JOIN tag t ON t.type_tag_class_id = tc.id
    JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    JOIN post p ON p.id = pht.post_id
    GROUP BY tc.id, tc.name
),
comment_stats AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT c.id) AS comment_cnt,
        AVG(c.length) AS avg_comment_len,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creator_cnt
    FROM tag_class tc
    JOIN tag t ON t.type_tag_class_id = tc.id
    JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    JOIN comment c ON c.id = cht.comment_id
    GROUP BY tc.id, tc.name
)
SELECT
    COALESCE(pc.tag_class_name, cc.tag_class_name) AS tag_class_name,
    COALESCE(pc.post_cnt, 0) AS post_cnt,
    COALESCE(pc.avg_post_len, 0) AS avg_post_len,
    COALESCE(pc.distinct_post_creator_cnt, 0) AS distinct_post_creator_cnt,
    COALESCE(cc.comment_cnt, 0) AS comment_cnt,
    COALESCE(cc.avg_comment_len, 0) AS avg_comment_len,
    COALESCE(cc.distinct_comment_creator_cnt, 0) AS distinct_comment_creator_cnt,
    (COALESCE(pc.post_cnt, 0) + COALESCE(cc.comment_cnt, 0)) AS total_activity
FROM post_stats pc
FULL OUTER JOIN comment_stats cc
    ON pc.tag_class_id = cc.tag_class_id
WHERE (COALESCE(pc.post_cnt, 0) + COALESCE(cc.comment_cnt, 0)) >= 100
ORDER BY total_activity DESC
LIMIT 10
