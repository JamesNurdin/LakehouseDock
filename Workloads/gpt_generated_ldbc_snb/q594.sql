WITH post_tag_usage AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT pht.post_id) AS post_count
    FROM post_has_tag_tag pht
    JOIN tag t          ON pht.tag_id = t.id
    JOIN tag_class tc   ON t.type_tag_class_id = tc.id
    GROUP BY tc.id, tc.name
),
comment_tag_usage AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT cht.comment_id) AS comment_count
    FROM comment_has_tag_tag cht
    JOIN tag t          ON cht.tag_id = t.id
    JOIN tag_class tc   ON t.type_tag_class_id = tc.id
    GROUP BY tc.id, tc.name
),
combined AS (
    SELECT
        COALESCE(ptu.tag_class_id,    ctu.tag_class_id)    AS tag_class_id,
        COALESCE(ptu.tag_class_name, ctu.tag_class_name) AS tag_class_name,
        COALESCE(ptu.post_count,    0)                  AS post_count,
        COALESCE(ctu.comment_count, 0)                  AS comment_count,
        COALESCE(ptu.post_count, 0) + COALESCE(ctu.comment_count, 0) AS total_usage
    FROM post_tag_usage    ptu
    FULL OUTER JOIN comment_tag_usage ctu
        ON ptu.tag_class_id = ctu.tag_class_id
)
SELECT
    tag_class_id,
    tag_class_name,
    post_count,
    comment_count,
    total_usage
FROM combined
ORDER BY total_usage DESC
LIMIT 10
