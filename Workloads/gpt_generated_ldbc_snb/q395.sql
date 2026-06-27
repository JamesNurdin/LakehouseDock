WITH forum_tag_counts AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date AS forum_creation_date,
        f.moderator_person_id,
        COUNT(fht.tag_id) AS tag_count
    FROM forum AS f
    LEFT JOIN forum_has_tag_tag AS fht
        ON fht.forum_id = f.id
    GROUP BY f.id, f.title, f.creation_date, f.moderator_person_id
)
SELECT
    moderator_person_id,
    COUNT(*) AS forum_count,
    SUM(tag_count) AS total_tag_assignments,
    AVG(tag_count) AS avg_tags_per_forum,
    SUM(CASE WHEN tag_count > 0 THEN 1 ELSE 0 END) AS forums_with_tags,
    MIN(forum_creation_date) AS earliest_forum_creation_date
FROM forum_tag_counts
WHERE forum_creation_date >= '2020-01-01'
GROUP BY moderator_person_id
ORDER BY total_tag_assignments DESC
LIMIT 10
