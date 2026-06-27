WITH direct_tag_counts AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(t.id) AS direct_tag_cnt,
        AVG(length(t.name)) AS avg_tag_name_len
    FROM tag t
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id, tc.name
),
subclass_tag_counts AS (
    SELECT
        parent.id AS parent_tag_class_id,
        parent.name AS parent_tag_class_name,
        SUM(COALESCE(dtc.direct_tag_cnt, 0)) AS subclass_tag_cnt,
        AVG(COALESCE(dtc.avg_tag_name_len, 0)) AS subclass_avg_tag_name_len
    FROM tag_class parent
    LEFT JOIN tag_class child
        ON child.subclass_of_tag_class_id = parent.id
    LEFT JOIN direct_tag_counts dtc
        ON dtc.tag_class_id = child.id
    GROUP BY parent.id, parent.name
)
SELECT
    p.id AS tag_class_id,
    p.name AS tag_class_name,
    COALESCE(dtc.direct_tag_cnt, 0) AS direct_tag_cnt,
    COALESCE(stc.subclass_tag_cnt, 0) AS subclass_tag_cnt,
    (COALESCE(dtc.direct_tag_cnt, 0) + COALESCE(stc.subclass_tag_cnt, 0)) AS total_tag_cnt,
    COALESCE(dtc.avg_tag_name_len, 0) AS direct_avg_tag_name_len,
    COALESCE(stc.subclass_avg_tag_name_len, 0) AS subclass_avg_tag_name_len,
    ((COALESCE(dtc.direct_tag_cnt, 0) * COALESCE(dtc.avg_tag_name_len, 0))
     + (COALESCE(stc.subclass_tag_cnt, 0) * COALESCE(stc.subclass_avg_tag_name_len, 0)))
    / NULLIF((COALESCE(dtc.direct_tag_cnt, 0) + COALESCE(stc.subclass_tag_cnt, 0)), 0) AS overall_avg_tag_name_len
FROM tag_class p
LEFT JOIN direct_tag_counts dtc
    ON dtc.tag_class_id = p.id
LEFT JOIN subclass_tag_counts stc
    ON stc.parent_tag_class_id = p.id
ORDER BY total_tag_cnt DESC
LIMIT 10
