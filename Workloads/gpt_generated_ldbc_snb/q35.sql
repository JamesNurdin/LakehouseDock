WITH post_tags AS (
    SELECT
        p.id AS post_id,
        t.id AS tag_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        pl.name AS country_name,
        p.length AS item_length,
        p.creator_person_id AS creator_person_id,
        'post' AS item_type
    FROM post_has_tag_tag pht
    JOIN post p ON p.id = pht.post_id
    JOIN tag t ON t.id = pht.tag_id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN place pl ON p.location_country_id = pl.id
),
comment_tags AS (
    SELECT
        c.id AS comment_id,
        t.id AS tag_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        pl.name AS country_name,
        c.length AS item_length,
        c.creator_person_id AS creator_person_id,
        'comment' AS item_type
    FROM comment_has_tag_tag cht
    JOIN comment c ON c.id = cht.comment_id
    JOIN tag t ON t.id = cht.tag_id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN place pl ON c.location_country_id = pl.id
),
all_tagged_items AS (
    SELECT
        tag_class_id,
        tag_class_name,
        country_name,
        item_type,
        item_length,
        creator_person_id
    FROM post_tags
    UNION ALL
    SELECT
        tag_class_id,
        tag_class_name,
        country_name,
        item_type,
        item_length,
        creator_person_id
    FROM comment_tags
)
SELECT
    tag_class_name,
    COALESCE(country_name, 'Unknown') AS country_name,
    COUNT(*) AS total_tagged_items,
    SUM(CASE WHEN item_type = 'post' THEN 1 ELSE 0 END) AS post_tagged_items,
    SUM(CASE WHEN item_type = 'comment' THEN 1 ELSE 0 END) AS comment_tagged_items,
    AVG(CASE WHEN item_type = 'post' THEN item_length END) AS avg_post_length,
    AVG(CASE WHEN item_type = 'comment' THEN item_length END) AS avg_comment_length,
    COUNT(DISTINCT creator_person_id) AS distinct_creators
FROM all_tagged_items
GROUP BY tag_class_name, country_name
ORDER BY total_tagged_items DESC
LIMIT 100
