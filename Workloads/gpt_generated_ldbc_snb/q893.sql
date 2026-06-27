/*
  Analytical query:  Top forums by activity
  - Number of posts in each forum
  - Number of distinct people who liked posts in the forum
  - Total number of comments on the forum’s posts
  - Average comments per post
  - Most frequent tag used on the forum’s posts (tag_id and its count)
*/
WITH forum_stats AS (
    SELECT
        f.id   AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT p.id)          AS total_posts,
        COUNT(DISTINCT plp.person_id) AS total_likes,
        COUNT(DISTINCT c.id)          AS total_comments
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.id, f.title
),
forum_tag_counts AS (
    SELECT
        f.id          AS forum_id,
        pht.tag_id,
        COUNT(*)      AS tag_count
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    GROUP BY f.id, pht.tag_id
),
forum_top_tag AS (
    SELECT
        forum_id,
        tag_id,
        tag_count,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_count DESC, tag_id) AS rn
    FROM forum_tag_counts
)
SELECT
    fs.forum_id,
    fs.forum_title,
    fs.total_posts,
    fs.total_likes,
    fs.total_comments,
    CASE WHEN fs.total_posts = 0 THEN 0.0
         ELSE CAST(fs.total_comments AS double) / fs.total_posts
    END AS avg_comments_per_post,
    ft.tag_id AS top_tag_id,
    ft.tag_count AS top_tag_count
FROM forum_stats fs
LEFT JOIN forum_top_tag ft
    ON ft.forum_id = fs.forum_id
   AND ft.rn = 1
ORDER BY fs.total_posts DESC
LIMIT 20
