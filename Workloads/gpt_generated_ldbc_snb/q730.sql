WITH tag_forum_stats AS (
    SELECT
        fht.tag_id,
        COUNT(DISTINCT fht.forum_id) AS forum_count,
        MIN(fht.creation_date) AS earliest_creation_date,
        MAX(fht.creation_date) AS latest_creation_date
    FROM forum_has_tag_tag AS fht
    GROUP BY fht.tag_id
)
SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    t.type_tag_class_id,
    t.url,
    s.forum_count,
    s.earliest_creation_date,
    s.latest_creation_date
FROM tag_forum_stats AS s
JOIN tag AS t
    ON s.tag_id = t.id
ORDER BY s.forum_count DESC
LIMIT 10
