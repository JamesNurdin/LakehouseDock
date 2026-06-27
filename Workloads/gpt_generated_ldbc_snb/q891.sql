WITH forum_tag_counts AS (
    SELECT
        f.id,
        f.title,
        f.moderator_person_id,
        f.creation_date AS forum_creation_date,
        COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum AS f
    JOIN forum_has_tag_tag AS ft
        ON ft.forum_id = f.id
    GROUP BY f.id, f.title, f.moderator_person_id, f.creation_date
)
SELECT
    substr(forum_creation_date, 1, 7) AS year_month,
    COUNT(*) AS forum_count,
    AVG(tag_count) AS avg_tags_per_forum,
    MAX(tag_count) AS max_tags,
    MIN(tag_count) AS min_tags
FROM forum_tag_counts
GROUP BY substr(forum_creation_date, 1, 7)
ORDER BY forum_count DESC
LIMIT 10
