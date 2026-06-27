WITH comment_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(c.id) AS comment_count,
        SUM(c.length) AS total_comment_length,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_commenters
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY t.id, t.name, tc.id, tc.name
),
post_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(p.id) AS post_count,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_posters
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY t.id, t.name, tc.id, tc.name
)
SELECT
    COALESCE(cs.tag_id, ps.tag_id) AS tag_id,
    COALESCE(cs.tag_name, ps.tag_name) AS tag_name,
    COALESCE(cs.tag_class_id, ps.tag_class_id) AS tag_class_id,
    COALESCE(cs.tag_class_name, ps.tag_class_name) AS tag_class_name,
    cs.comment_count,
    cs.total_comment_length,
    cs.avg_comment_length,
    cs.distinct_commenters,
    ps.post_count,
    ps.total_post_length,
    ps.avg_post_length,
    ps.distinct_posters
FROM comment_stats cs
FULL OUTER JOIN post_stats ps
    ON cs.tag_id = ps.tag_id
ORDER BY (COALESCE(cs.comment_count, 0) + COALESCE(ps.post_count, 0)) DESC
LIMIT 10
