WITH comment_usage AS (
    SELECT
        t.type_tag_class_id AS tag_class_id,
        COUNT(DISTINCT cht.comment_id) AS comment_cnt,
        COUNT(DISTINCT t.id) AS distinct_tag_cnt
    FROM comment_has_tag_tag cht
    JOIN tag t ON cht.tag_id = t.id
    GROUP BY t.type_tag_class_id
),
forum_usage AS (
    SELECT
        t.type_tag_class_id AS tag_class_id,
        COUNT(DISTINCT fht.forum_id) AS forum_cnt,
        COUNT(DISTINCT t.id) AS distinct_tag_cnt
    FROM forum_has_tag_tag fht
    JOIN tag t ON fht.tag_id = t.id
    GROUP BY t.type_tag_class_id
),
person_usage AS (
    SELECT
        t.type_tag_class_id AS tag_class_id,
        COUNT(DISTINCT pht.person_id) AS person_cnt,
        COUNT(DISTINCT t.id) AS distinct_tag_cnt
    FROM person_has_interest_tag pht
    JOIN tag t ON pht.tag_id = t.id
    GROUP BY t.type_tag_class_id
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    COALESCE(cu.comment_cnt, 0) AS comment_cnt,
    COALESCE(fu.forum_cnt, 0) AS forum_cnt,
    COALESCE(pu.person_cnt, 0) AS person_cnt,
    (COALESCE(cu.distinct_tag_cnt, 0) + COALESCE(fu.distinct_tag_cnt, 0) + COALESCE(pu.distinct_tag_cnt, 0)) AS distinct_tag_cnt_total,
    (COALESCE(cu.comment_cnt, 0) + COALESCE(fu.forum_cnt, 0) + COALESCE(pu.person_cnt, 0)) AS total_usage,
    CASE
        WHEN (COALESCE(cu.comment_cnt, 0) + COALESCE(fu.forum_cnt, 0) + COALESCE(pu.person_cnt, 0)) > 0
        THEN (COALESCE(cu.comment_cnt, 0) * 1.0) / (COALESCE(cu.comment_cnt, 0) + COALESCE(fu.forum_cnt, 0) + COALESCE(pu.person_cnt, 0))
        ELSE 0
    END AS comment_usage_ratio
FROM tag_class tc
LEFT JOIN comment_usage cu ON tc.id = cu.tag_class_id
LEFT JOIN forum_usage fu ON tc.id = fu.tag_class_id
LEFT JOIN person_usage pu ON tc.id = pu.tag_class_id
ORDER BY total_usage DESC
LIMIT 20
