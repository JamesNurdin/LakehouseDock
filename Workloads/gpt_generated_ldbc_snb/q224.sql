WITH comment_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creators,
        COUNT(plc.person_id) AS comment_like_count,
        COUNT(DISTINCT plc.person_id) AS distinct_comment_likers
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    LEFT JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY t.id, t.name, tc.name
),
post_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    GROUP BY t.id
)
SELECT
    cs.tag_id,
    cs.tag_name,
    cs.tag_class_name,
    cs.comment_count,
    cs.avg_comment_length,
    cs.distinct_comment_creators,
    cs.comment_like_count,
    cs.distinct_comment_likers,
    COALESCE(ps.post_count, 0) AS post_count,
    ps.avg_post_length,
    ps.distinct_post_creators
FROM comment_stats cs
LEFT JOIN post_stats ps ON cs.tag_id = ps.tag_id
ORDER BY cs.comment_count DESC, COALESCE(ps.post_count, 0) DESC
LIMIT 10
