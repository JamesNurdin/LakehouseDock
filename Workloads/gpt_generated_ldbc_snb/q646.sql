WITH tag_usage AS (
    SELECT
        t.id AS tag_id,
        t.name,
        t.type_tag_class_id,
        COUNT(DISTINCT pht.post_id) AS post_cnt,
        MIN(pht.creation_date) AS first_appearance,
        MAX(pht.creation_date) AS last_appearance
    FROM post_has_tag_tag pht
    JOIN tag t
        ON pht.tag_id = t.id
    GROUP BY t.id, t.name, t.type_tag_class_id
),
ranked_tags AS (
    SELECT
        tag_id,
        name,
        type_tag_class_id,
        post_cnt,
        first_appearance,
        last_appearance,
        RANK() OVER (PARTITION BY type_tag_class_id ORDER BY post_cnt DESC) AS rank_in_type
    FROM tag_usage
)
SELECT
    tag_id,
    name,
    type_tag_class_id,
    post_cnt,
    first_appearance,
    last_appearance,
    rank_in_type
FROM ranked_tags
WHERE rank_in_type <= 5
ORDER BY type_tag_class_id, rank_in_type
