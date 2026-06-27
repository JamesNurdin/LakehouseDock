WITH comment_tag_class_country AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        pl.id AS country_id,
        pl.name AS country_name,
        COUNT(*) AS comment_cnt,
        SUM(c.length) AS sum_length
    FROM comment c
    JOIN comment_has_tag_tag ctt ON ctt.comment_id = c.id
    JOIN tag t ON ctt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN place pl ON c.location_country_id = pl.id
    GROUP BY tc.id, tc.name, pl.id, pl.name
),
tag_class_total AS (
    SELECT
        tag_class_id,
        tag_class_name,
        SUM(comment_cnt) AS total_comments,
        SUM(sum_length) AS total_length
    FROM comment_tag_class_country
    GROUP BY tag_class_id, tag_class_name
),
tag_class_distinct_commenters AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT c.creator_person_id) AS distinct_commenters
    FROM comment c
    JOIN comment_has_tag_tag ctt ON ctt.comment_id = c.id
    JOIN tag t ON ctt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
top_country AS (
    SELECT
        tag_class_id,
        country_name,
        comment_cnt,
        ROW_NUMBER() OVER (PARTITION BY tag_class_id ORDER BY comment_cnt DESC) AS rn
    FROM comment_tag_class_country
)
SELECT
    tct.tag_class_name,
    tct.total_comments,
    tcdc.distinct_commenters,
    CAST(tct.total_length AS double) / NULLIF(tct.total_comments, 0) AS avg_comment_length,
    tc.country_name AS top_country,
    tc.comment_cnt AS top_country_comment_cnt
FROM tag_class_total tct
JOIN tag_class_distinct_commenters tcdc
    ON tct.tag_class_id = tcdc.tag_class_id
JOIN top_country tc
    ON tct.tag_class_id = tc.tag_class_id
WHERE tc.rn = 1
ORDER BY tct.total_comments DESC
LIMIT 10
