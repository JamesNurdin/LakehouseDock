WITH post_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT pht.post_id) AS post_cnt,
        AVG(p.length) AS avg_post_len
    FROM post_has_tag_tag pht
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN post p ON p.id = pht.post_id
    GROUP BY tc.id, tc.name
),
comment_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT cht.comment_id) AS comment_cnt
    FROM comment_has_tag_tag cht
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
forum_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT fht.forum_id) AS forum_cnt
    FROM forum_has_tag_tag fht
    JOIN tag t ON fht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
person_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pit.person_id) AS person_cnt
    FROM person_has_interest_tag pit
    JOIN tag t ON pit.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
combined_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COALESCE(pm.post_cnt, 0) AS post_cnt,
        COALESCE(pm.avg_post_len, 0) AS avg_post_len,
        COALESCE(cm.comment_cnt, 0) AS comment_cnt,
        COALESCE(fm.forum_cnt, 0) AS forum_cnt,
        COALESCE(pim.person_cnt, 0) AS person_cnt,
        ptc.name AS parent_tag_class_name
    FROM tag_class tc
    LEFT JOIN post_metrics pm ON pm.tag_class_id = tc.id
    LEFT JOIN comment_metrics cm ON cm.tag_class_id = tc.id
    LEFT JOIN forum_metrics fm ON fm.tag_class_id = tc.id
    LEFT JOIN person_metrics pim ON pim.tag_class_id = tc.id
    LEFT JOIN tag_class ptc ON tc.subclass_of_tag_class_id = ptc.id
)
SELECT
    tag_class_id,
    tag_class_name,
    parent_tag_class_name,
    post_cnt,
    avg_post_len,
    comment_cnt,
    forum_cnt,
    person_cnt,
    ROW_NUMBER() OVER (ORDER BY post_cnt DESC) AS post_rank
FROM combined_metrics
ORDER BY post_cnt DESC
LIMIT 100
