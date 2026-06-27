WITH comment_tag_usage AS (
    SELECT
        t.id AS tag_id,
        t.type_tag_class_id AS tag_class_id,
        cht.comment_id AS comment_id
    FROM comment_has_tag_tag cht
    JOIN tag t ON cht.tag_id = t.id
),
post_tag_usage AS (
    SELECT
        t.id AS tag_id,
        t.type_tag_class_id AS tag_class_id,
        pht.post_id AS post_id
    FROM post_has_tag_tag pht
    JOIN tag t ON pht.tag_id = t.id
),
comment_counts_by_class AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT ctu.comment_id) AS comment_cnt
    FROM comment_tag_usage ctu
    JOIN tag_class tc ON ctu.tag_class_id = tc.id
    GROUP BY tc.id
),
post_counts_by_class AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT ptu.post_id) AS post_cnt
    FROM post_tag_usage ptu
    JOIN tag_class tc ON ptu.tag_class_id = tc.id
    GROUP BY tc.id
),
parent_class_aggregation AS (
    SELECT
        COALESCE(parent.id, child.id) AS agg_tag_class_id,
        COALESCE(parent.name, child.name) AS agg_tag_class_name,
        SUM(cc.comment_cnt) AS total_comment_cnt,
        SUM(pc.post_cnt) AS total_post_cnt
    FROM tag_class child
    LEFT JOIN tag_class parent ON child.subclass_of_tag_class_id = parent.id
    LEFT JOIN comment_counts_by_class cc ON child.id = cc.tag_class_id
    LEFT JOIN post_counts_by_class pc ON child.id = pc.tag_class_id
    GROUP BY COALESCE(parent.id, child.id), COALESCE(parent.name, child.name)
)
SELECT
    agg_tag_class_id,
    agg_tag_class_name,
    total_comment_cnt,
    total_post_cnt,
    CAST(total_comment_cnt AS double) / NULLIF(total_post_cnt, 0) AS comment_to_post_ratio
FROM parent_class_aggregation
ORDER BY total_comment_cnt DESC
LIMIT 50
