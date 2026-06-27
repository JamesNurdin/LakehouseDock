WITH post_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.length) AS total_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_authors
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
    JOIN tag t ON pt.tag_id = t.id
    GROUP BY t.id, t.name
),
comment_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(c.length) AS total_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_authors
    FROM comment_has_tag_tag ct
    JOIN comment c ON ct.comment_id = c.id
    JOIN tag t ON ct.tag_id = t.id
    GROUP BY t.id, t.name
)
SELECT
    COALESCE(p.tag_id, co.tag_id) AS tag_id,
    COALESCE(p.tag_name, co.tag_name) AS tag_name,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(co.comment_count, 0) AS comment_count,
    COALESCE(p.total_post_length, 0) AS total_post_length,
    COALESCE(co.total_comment_length, 0) AS total_comment_length,
    COALESCE(p.distinct_post_authors, 0) AS distinct_post_authors,
    COALESCE(co.distinct_comment_authors, 0) AS distinct_comment_authors,
    CASE
        WHEN COALESCE(p.post_count, 0) + COALESCE(co.comment_count, 0) = 0 THEN 0
        ELSE (COALESCE(p.total_post_length, 0) + COALESCE(co.total_comment_length, 0)) * 1.0
             / (COALESCE(p.post_count, 0) + COALESCE(co.comment_count, 0))
    END AS avg_length_per_item
FROM post_stats p
FULL OUTER JOIN comment_stats co ON p.tag_id = co.tag_id
ORDER BY post_count DESC, comment_count DESC
LIMIT 20
