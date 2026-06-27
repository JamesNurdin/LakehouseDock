WITH tags_filtered AS (
    SELECT id, name
    FROM tag
    WHERE type_tag_class_id = 1
),
post_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM tags_filtered t
    JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    JOIN post p ON p.id = pht.post_id
    GROUP BY t.id
),
comment_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT c.comment_id) AS comment_count
    FROM tags_filtered t
    JOIN comment_has_tag_tag c ON c.tag_id = t.id
    GROUP BY t.id
),
forum_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT f.forum_id) AS forum_count
    FROM tags_filtered t
    JOIN forum_has_tag_tag f ON f.tag_id = t.id
    GROUP BY t.id
),
person_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT p.person_id) AS person_interest_count
    FROM tags_filtered t
    JOIN person_has_interest_tag p ON p.tag_id = t.id
    GROUP BY t.id
)
SELECT
    t.id,
    t.name,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(fs.forum_count, 0) AS forum_count,
    COALESCE(pis.person_interest_count, 0) AS person_interest_count
FROM tags_filtered t
LEFT JOIN post_stats ps ON ps.tag_id = t.id
LEFT JOIN comment_stats cs ON cs.tag_id = t.id
LEFT JOIN forum_stats fs ON fs.tag_id = t.id
LEFT JOIN person_stats pis ON pis.tag_id = t.id
ORDER BY post_count DESC, comment_count DESC
LIMIT 100
