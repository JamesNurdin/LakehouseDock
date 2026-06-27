WITH comment_tag_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_authors
    FROM comment c
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    JOIN tag t ON ct.tag_id = t.id
    GROUP BY t.id, t.name
),
post_tag_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_authors
    FROM post p
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    JOIN tag t ON pt.tag_id = t.id
    GROUP BY t.id, t.name
)
SELECT
    COALESCE(ct.tag_id, pt.tag_id) AS tag_id,
    COALESCE(ct.tag_name, pt.tag_name) AS tag_name,
    ct.comment_count,
    ct.avg_comment_length,
    ct.distinct_comment_authors,
    pt.post_count,
    pt.avg_post_length,
    pt.distinct_post_authors
FROM comment_tag_stats ct
FULL OUTER JOIN post_tag_stats pt
    ON ct.tag_id = pt.tag_id
ORDER BY COALESCE(ct.tag_name, pt.tag_name)
