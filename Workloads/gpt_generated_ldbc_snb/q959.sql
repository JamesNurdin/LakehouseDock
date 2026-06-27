WITH post_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post_has_tag_tag pht
    JOIN post p ON p.id = pht.post_id
    JOIN tag t ON t.id = pht.tag_id
    GROUP BY t.id
),
forum_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT f.id) AS forum_count
    FROM forum_has_tag_tag fht
    JOIN forum f ON f.id = fht.forum_id
    JOIN tag t ON t.id = fht.tag_id
    GROUP BY t.id
),
person_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT pih.person_id) AS person_count
    FROM person_has_interest_tag pih
    JOIN tag t ON t.id = pih.tag_id
    GROUP BY t.id
),
comment_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT cht.comment_id) AS comment_count
    FROM comment_has_tag_tag cht
    JOIN tag t ON t.id = cht.tag_id
    GROUP BY t.id
)
SELECT
    tc.name AS tag_class_name,
    parent_tc.name AS parent_tag_class_name,
    t.name AS tag_name,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(fs.forum_count, 0) AS forum_count,
    COALESCE(pis.person_count, 0) AS person_count,
    ps.avg_post_length
FROM tag t
JOIN tag_class tc ON t.type_tag_class_id = tc.id
LEFT JOIN tag_class parent_tc ON tc.subclass_of_tag_class_id = parent_tc.id
LEFT JOIN post_stats ps ON ps.tag_id = t.id
LEFT JOIN forum_stats fs ON fs.tag_id = t.id
LEFT JOIN person_stats pis ON pis.tag_id = t.id
LEFT JOIN comment_stats cs ON cs.tag_id = t.id
ORDER BY post_count DESC, comment_count DESC
LIMIT 100
