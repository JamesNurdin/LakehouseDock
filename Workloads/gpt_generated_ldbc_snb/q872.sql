WITH post_agg AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT p.id)       AS post_count,
        AVG(p.length)              AS avg_post_length
    FROM post_has_tag_tag pt
    JOIN tag t        ON pt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN post p       ON pt.post_id = p.id
    GROUP BY tc.id, tc.name
),
comment_agg AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT c.id)       AS comment_count,
        AVG(c.length)              AS avg_comment_length
    FROM comment_has_tag_tag ct
    JOIN tag t        ON ct.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN comment c    ON ct.comment_id = c.id
    GROUP BY tc.id, tc.name
),
person_agg AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT per.id) AS interested_person_count
    FROM person_has_interest_tag pit
    JOIN tag t        ON pit.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN person per   ON pit.person_id = per.id
    GROUP BY tc.id, tc.name
)
SELECT
    COALESCE(p.tag_class_id, co.tag_class_id, per.tag_class_id) AS tag_class_id,
    COALESCE(p.tag_class_name, co.tag_class_name, per.tag_class_name) AS tag_class_name,
    COALESCE(p.post_count, 0)            AS post_count,
    COALESCE(p.avg_post_length, 0)       AS avg_post_length,
    COALESCE(co.comment_count, 0)        AS comment_count,
    COALESCE(co.avg_comment_length, 0)   AS avg_comment_length,
    COALESCE(per.interested_person_count, 0) AS interested_person_count,
    (COALESCE(p.post_count, 0) + COALESCE(co.comment_count, 0)) AS total_activity
FROM post_agg p
FULL OUTER JOIN comment_agg co
    ON p.tag_class_id = co.tag_class_id
FULL OUTER JOIN person_agg per
    ON COALESCE(p.tag_class_id, co.tag_class_id) = per.tag_class_id
ORDER BY total_activity DESC
LIMIT 10
