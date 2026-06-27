WITH member_stats AS (
    SELECT
        forum_id,
        COUNT(*) AS member_count,
        MIN(creation_date) AS member_creation_min
    FROM forum_has_member_person
    GROUP BY forum_id
),
tag_stats AS (
    SELECT
        forum_id,
        COUNT(*) AS tag_count,
        MIN(creation_date) AS tag_creation_min
    FROM forum_has_tag_tag
    GROUP BY forum_id
),
post_stats AS (
    SELECT
        container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        SUM(length) AS total_post_length,
        AVG(length) AS avg_post_length,
        COUNT(DISTINCT language) AS distinct_languages,
        MIN(creation_date) AS post_creation_min
    FROM post
    GROUP BY container_forum_id
)
SELECT
    f.id,
    f.title,
    f.moderator_person_id,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_length, 0) AS total_post_length,
    p.avg_post_length,
    p.distinct_languages,
    LEAST(
        f.creation_date,
        COALESCE(m.member_creation_min, f.creation_date),
        COALESCE(t.tag_creation_min, f.creation_date),
        COALESCE(p.post_creation_min, f.creation_date)
    ) AS earliest_creation_date
FROM forum AS f
LEFT JOIN member_stats AS m
    ON m.forum_id = f.id
LEFT JOIN tag_stats AS t
    ON t.forum_id = f.id
LEFT JOIN post_stats AS p
    ON p.forum_id = f.id
ORDER BY p.avg_post_length DESC
LIMIT 10
