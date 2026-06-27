WITH forum_tag_counts AS (
    SELECT
        f.id,
        f.title,
        f.moderator_person_id,
        COUNT(fht.tag_id) AS tag_count,
        COUNT(DISTINCT fht.tag_id) AS distinct_tag_count
    FROM forum AS f
    JOIN forum_has_tag_tag AS fht
        ON fht.forum_id = f.id
    GROUP BY f.id, f.title, f.moderator_person_id
),
moderator_stats AS (
    SELECT
        moderator_person_id,
        SUM(tag_count) AS total_tags,
        AVG(tag_count) AS avg_tags_per_forum,
        COUNT(*) AS forum_count
    FROM forum_tag_counts
    GROUP BY moderator_person_id
)
SELECT
    ftc.id AS forum_id,
    ftc.title,
    ftc.moderator_person_id,
    ftc.tag_count,
    ftc.distinct_tag_count,
    ms.total_tags,
    ms.avg_tags_per_forum,
    ms.forum_count
FROM forum_tag_counts AS ftc
JOIN moderator_stats AS ms
    ON ftc.moderator_person_id = ms.moderator_person_id
ORDER BY ftc.tag_count DESC, ftc.id
LIMIT 100
