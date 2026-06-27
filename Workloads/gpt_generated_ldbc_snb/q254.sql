WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title
    FROM forum f
),
post_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
comment_agg AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(CAST(c.length AS double)) AS avg_comment_length,
           COUNT(DISTINCT c.creator_person_id) AS distinct_commenter_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
post_tag_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT pt.tag_id) AS distinct_post_tag_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    GROUP BY f.id
),
comment_tag_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT ct.tag_id) AS distinct_comment_tag_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    GROUP BY f.id
)
SELECT
    fb.forum_id,
    fb.forum_title,
    COALESCE(pc.post_count, 0) AS post_count,
    COALESCE(ca.comment_count, 0) AS comment_count,
    ca.avg_comment_length,
    COALESCE(ptc.distinct_post_tag_count, 0) AS distinct_post_tag_count,
    COALESCE(ctc.distinct_comment_tag_count, 0) AS distinct_comment_tag_count,
    COALESCE(ca.distinct_commenter_count, 0) AS distinct_commenter_count
FROM forum_base fb
LEFT JOIN post_counts pc ON pc.forum_id = fb.forum_id
LEFT JOIN comment_agg ca ON ca.forum_id = fb.forum_id
LEFT JOIN post_tag_counts ptc ON ptc.forum_id = fb.forum_id
LEFT JOIN comment_tag_counts ctc ON ctc.forum_id = fb.forum_id
ORDER BY post_count DESC
LIMIT 10
