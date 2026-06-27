WITH comment_tag AS (
    SELECT
        c.id AS comment_id,
        c.creation_date AS comment_creation_date,
        c.length,
        c.creator_person_id,
        c.location_country_id,
        c.parent_comment_id,
        t.id AS tag_id,
        t.name AS tag_name,
        t.type_tag_class_id,
        ct.creation_date AS ct_creation_date
    FROM comment c
    JOIN comment_has_tag_tag ct
        ON ct.comment_id = c.id
    JOIN tag t
        ON ct.tag_id = t.id
),
place_hierarchy AS (
    SELECT
        p.id AS country_id,
        p.name AS country_name,
        p.type AS country_type,
        p.part_of_place_id AS region_id,
        p_parent.name AS region_name,
        p_parent.type AS region_type
    FROM place p
    LEFT JOIN place p_parent
        ON p.part_of_place_id = p_parent.id
),
tag_stats AS (
    SELECT
        ct.tag_id,
        ct.tag_name,
        ph.region_name,
        COUNT(*) AS comment_count,
        AVG(ct.length) AS avg_comment_length,
        COUNT(DISTINCT ct.creator_person_id) AS distinct_creators,
        SUM(CASE WHEN pc.id IS NOT NULL THEN 1 ELSE 0 END) AS reply_count
    FROM comment_tag ct
    JOIN place_hierarchy ph
        ON ct.location_country_id = ph.country_id
    LEFT JOIN comment pc
        ON pc.parent_comment_id = ct.comment_id
    GROUP BY ct.tag_id, ct.tag_name, ph.region_name
)
SELECT
    tag_id,
    tag_name,
    region_name,
    comment_count,
    avg_comment_length,
    distinct_creators,
    reply_count,
    ROW_NUMBER() OVER (PARTITION BY region_name ORDER BY comment_count DESC) AS tag_rank_in_region
FROM tag_stats
ORDER BY region_name, tag_rank_in_region
