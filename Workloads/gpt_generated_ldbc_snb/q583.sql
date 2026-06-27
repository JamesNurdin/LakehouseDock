/*
  Top 10 tags by total likes on posts and comments.
  For each tag the query returns:
    • Number of likes on posts that carry the tag
    • Number of likes on comments that carry the tag
    • Total likes (posts + comments)
    • Count of distinct people who liked either a post or a comment with the tag
    • Average length of the tagged posts
    • Average length of the tagged comments
*/
WITH post_like_stats AS (
    SELECT
        tag.id   AS tag_id,
        tag.name AS tag_name,
        COUNT(*)                               AS post_likes,
        COUNT(DISTINCT person_likes_post.person_id) AS distinct_post_likers,
        AVG(post.length)                       AS avg_post_length
    FROM tag
    JOIN post_has_tag_tag   ON post_has_tag_tag.tag_id = tag.id
    JOIN post               ON post.id = post_has_tag_tag.post_id
    JOIN person_likes_post  ON person_likes_post.post_id = post.id
    GROUP BY tag.id, tag.name
),
comment_like_stats AS (
    SELECT
        tag.id   AS tag_id,
        tag.name AS tag_name,
        COUNT(*)                               AS comment_likes,
        COUNT(DISTINCT person_likes_comment.person_id) AS distinct_comment_likers,
        AVG(comment.length)                    AS avg_comment_length
    FROM tag
    JOIN comment_has_tag_tag ON comment_has_tag_tag.tag_id = tag.id
    JOIN comment             ON comment.id = comment_has_tag_tag.comment_id
    JOIN person_likes_comment ON person_likes_comment.comment_id = comment.id
    GROUP BY tag.id, tag.name
),
/*
  Compute the exact number of distinct people who liked either a post or a comment
  that is associated with each tag.  The UNION ALL gathers all (tag, person) pairs
  from post‑likes and comment‑likes; the outer aggregation then counts distinct persons.
*/
distinct_likers_agg AS (
    SELECT
        liker.tag_id AS tag_id,
        COUNT(DISTINCT liker.person_id) AS total_distinct_likers
    FROM (
        SELECT
            tag.id   AS tag_id,
            person_likes_post.person_id AS person_id
        FROM tag
        JOIN post_has_tag_tag   ON post_has_tag_tag.tag_id = tag.id
        JOIN post               ON post.id = post_has_tag_tag.post_id
        JOIN person_likes_post  ON person_likes_post.post_id = post.id
        UNION ALL
        SELECT
            tag.id   AS tag_id,
            person_likes_comment.person_id AS person_id
        FROM tag
        JOIN comment_has_tag_tag ON comment_has_tag_tag.tag_id = tag.id
        JOIN comment             ON comment.id = comment_has_tag_tag.comment_id
        JOIN person_likes_comment ON person_likes_comment.comment_id = comment.id
    ) AS liker
    GROUP BY liker.tag_id
),
combined AS (
    SELECT
        COALESCE(p.tag_id, c.tag_id)   AS tag_id,
        COALESCE(p.tag_name, c.tag_name) AS tag_name,
        COALESCE(p.post_likes, 0)      AS post_likes,
        COALESCE(c.comment_likes, 0)   AS comment_likes,
        COALESCE(p.avg_post_length, 0) AS avg_post_length,
        COALESCE(c.avg_comment_length, 0) AS avg_comment_length
    FROM post_like_stats p
    FULL OUTER JOIN comment_like_stats c ON c.tag_id = p.tag_id
)
SELECT
    combined.tag_name,
    combined.post_likes,
    combined.comment_likes,
    (combined.post_likes + combined.comment_likes) AS total_likes,
    COALESCE(distinct_likers_agg.total_distinct_likers, 0) AS total_distinct_likers,
    combined.avg_post_length,
    combined.avg_comment_length
FROM combined
LEFT JOIN distinct_likers_agg
    ON distinct_likers_agg.tag_id = combined.tag_id
ORDER BY total_likes DESC
LIMIT 10
