/*
  Analytical query: For each tag, compute the total content length and number of likes for posts and comments that carry the tag,
  as well as the number of distinct persons who liked any post or comment with that tag.
  The result is ordered by the number of distinct likers (descending) and then by total post likes.
*/
WITH post_stats AS (
    SELECT
        tht.tag_id,
        SUM(p.length) AS total_post_content_length,
        COUNT(plp.person_id) AS total_likes_on_posts
    FROM post_has_tag_tag tht
    JOIN post p ON tht.post_id = p.id
    JOIN person_likes_post plp ON p.id = plp.post_id
    GROUP BY tht.tag_id
),
comment_stats AS (
    SELECT
        cht.tag_id,
        SUM(c.length) AS total_comment_content_length,
        COUNT(clc.person_id) AS total_likes_on_comments
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN person_likes_comment clc ON c.id = clc.comment_id
    GROUP BY cht.tag_id
),
liker_stats AS (
    SELECT
        tag_id,
        COUNT(DISTINCT person_id) AS distinct_likers
    FROM (
        SELECT tht.tag_id, plp.person_id
        FROM post_has_tag_tag tht
        JOIN person_likes_post plp ON tht.post_id = plp.post_id
        UNION ALL
        SELECT cht.tag_id, clc.person_id
        FROM comment_has_tag_tag cht
        JOIN person_likes_comment clc ON cht.comment_id = clc.comment_id
    ) AS all_likes
    GROUP BY tag_id
)
SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    COALESCE(ps.total_post_content_length, 0) AS total_post_content_length,
    COALESCE(ps.total_likes_on_posts, 0) AS total_likes_on_posts,
    COALESCE(cs.total_comment_content_length, 0) AS total_comment_content_length,
    COALESCE(cs.total_likes_on_comments, 0) AS total_likes_on_comments,
    COALESCE(ls.distinct_likers, 0) AS distinct_likers
FROM tag t
LEFT JOIN post_stats ps ON t.id = ps.tag_id
LEFT JOIN comment_stats cs ON t.id = cs.tag_id
LEFT JOIN liker_stats ls ON t.id = ls.tag_id
ORDER BY distinct_likers DESC, total_likes_on_posts DESC
LIMIT 20
