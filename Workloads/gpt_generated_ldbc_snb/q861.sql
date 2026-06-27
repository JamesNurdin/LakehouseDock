WITH forum_tag_post_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht
        ON p.id = pht.post_id
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    GROUP BY
        f.id,
        f.title,
        tc.id,
        tc.name
),
forum_tag_comment_stats AS (
    SELECT
        f.id AS forum_id,
        tc.id AS tag_class_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    JOIN forum f
        ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht
        ON p.id = pht.post_id
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    GROUP BY
        f.id,
        tc.id
)
SELECT
    pstats.forum_id,
    pstats.forum_title,
    pstats.tag_class_id,
    pstats.tag_class_name,
    pstats.post_count,
    pstats.avg_post_length,
    COALESCE(cstats.comment_count, 0) AS comment_count,
    cstats.avg_comment_length
FROM forum_tag_post_stats pstats
LEFT JOIN forum_tag_comment_stats cstats
    ON pstats.forum_id = cstats.forum_id
   AND pstats.tag_class_id = cstats.tag_class_id
ORDER BY pstats.post_count DESC
LIMIT 10
