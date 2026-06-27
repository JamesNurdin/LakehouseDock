WITH tag_forum_stats AS (
    SELECT
        t.id,
        t.name,
        t.url,
        t.type_tag_class_id,
        COUNT(DISTINCT fht.forum_id) AS forum_count,
        COUNT(*) AS association_count,
        MIN(fht.creation_date) AS earliest_creation_date,
        MAX(fht.creation_date) AS latest_creation_date
    FROM forum_has_tag_tag fht
    JOIN tag t
        ON fht.tag_id = t.id
    GROUP BY t.id, t.name, t.url, t.type_tag_class_id
)
SELECT
    id,
    name,
    url,
    type_tag_class_id,
    forum_count,
    association_count,
    earliest_creation_date,
    latest_creation_date,
    RANK() OVER (PARTITION BY type_tag_class_id ORDER BY forum_count DESC) AS tag_rank_within_type
FROM tag_forum_stats
ORDER BY forum_count DESC
LIMIT 20
