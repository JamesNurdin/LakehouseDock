WITH comment_likes AS (
    SELECT comment_id,
           COUNT(*) AS like_cnt
    FROM person_likes_comment
    GROUP BY comment_id
),
forum_comment_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT c.id) AS total_comments,
        COALESCE(SUM(c.length), 0) AS sum_comment_length,
        COALESCE(SUM(COALESCE(cl.like_cnt, 0)), 0) AS total_comment_likes
    FROM forum AS f
    JOIN post AS p
        ON p.container_forum_id = f.id
    LEFT JOIN comment AS c
        ON c.parent_post_id = p.id
    LEFT JOIN comment_likes AS cl
        ON cl.comment_id = c.id
    GROUP BY f.id, f.title
),
forum_tag_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT t.id) AS distinct_tags,
        COUNT(DISTINCT tc.id) AS distinct_tag_classes
    FROM forum AS f
    JOIN post AS p
        ON p.container_forum_id = f.id
    LEFT JOIN comment AS c
        ON c.parent_post_id = p.id
    LEFT JOIN comment_has_tag_tag AS cht
        ON cht.comment_id = c.id
    LEFT JOIN tag AS t
        ON t.id = cht.tag_id
    LEFT JOIN tag_class AS tc
        ON tc.id = t.type_tag_class_id
    GROUP BY f.id
)
SELECT
    fcs.forum_id,
    fcs.forum_title,
    fcs.total_comments,
    CASE WHEN fcs.total_comments = 0 THEN 0
         ELSE fcs.sum_comment_length * 1.0 / fcs.total_comments
    END AS avg_comment_length,
    fcs.total_comment_likes,
    CASE WHEN fcs.total_comments = 0 THEN 0
         ELSE fcs.total_comment_likes * 1.0 / fcs.total_comments
    END AS avg_likes_per_comment,
    fts.distinct_tags,
    fts.distinct_tag_classes
FROM forum_comment_stats AS fcs
LEFT JOIN forum_tag_stats AS fts
    ON fts.forum_id = fcs.forum_id
ORDER BY fcs.total_comments DESC
LIMIT 10
