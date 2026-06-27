WITH comment_stats AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name,
        COUNT(DISTINCT c.id) AS comment_count,
        COALESCE(SUM(c.length), 0) AS total_comment_length
    FROM person p
    JOIN comment c ON c.creator_person_id = p.id
    GROUP BY p.id, p.first_name, p.last_name
),
likes_stats AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT plc.comment_id) AS likes_given
    FROM person p
    LEFT JOIN person_likes_comment plc ON plc.person_id = p.id
    GROUP BY p.id
),
tag_stats AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT t.id) AS distinct_tags_on_comments
    FROM person p
    JOIN comment c ON c.creator_person_id = p.id
    LEFT JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    LEFT JOIN tag t ON t.id = cht.tag_id
    GROUP BY p.id
)
SELECT
    cs.person_id,
    cs.first_name,
    cs.last_name,
    cs.comment_count,
    cs.total_comment_length,
    COALESCE(ls.likes_given, 0) AS likes_given,
    COALESCE(ts.distinct_tags_on_comments, 0) AS distinct_tags_on_comments
FROM comment_stats cs
LEFT JOIN likes_stats ls ON ls.person_id = cs.person_id
LEFT JOIN tag_stats ts ON ts.person_id = cs.person_id
ORDER BY cs.total_comment_length DESC
LIMIT 100
