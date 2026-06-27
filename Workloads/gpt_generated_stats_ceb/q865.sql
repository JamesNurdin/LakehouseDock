WITH tag_post_join AS (
    SELECT
        tags.id AS tag_id,
        tags.count AS tag_use_count,
        posts.id AS post_id,
        posts.posttypeid,
        posts.creationdate,
        posts.score,
        posts.viewcount,
        posts.owneruserid,
        posts.answercount,
        posts.commentcount,
        posts.favoritecount,
        posts.lasteditoruserid
    FROM tags
    JOIN posts ON tags.excerptpostid = posts.id
    WHERE posts.posttypeid = 1
      AND tags.count > 0
),

tag_aggregates AS (
    SELECT
        tag_id,
        tag_use_count,
        COUNT(post_id) AS num_posts,
        SUM(score) AS total_score,
        AVG(score) AS avg_score,
        SUM(viewcount) AS total_views,
        AVG(viewcount) AS avg_views,
        SUM(answercount) AS total_answers,
        AVG(answercount) AS avg_answers,
        SUM(commentcount) AS total_comments,
        AVG(commentcount) AS avg_comments,
        SUM(favoritecount) AS total_favorites,
        AVG(favoritecount) AS avg_favorites,
        COUNT(DISTINCT owneruserid) AS distinct_owners
    FROM tag_post_join
    GROUP BY tag_id, tag_use_count
)
SELECT
    tag_id,
    tag_use_count,
    num_posts,
    total_score,
    avg_score,
    total_views,
    avg_views,
    total_answers,
    avg_answers,
    total_comments,
    avg_comments,
    total_favorites,
    avg_favorites,
    distinct_owners,
    RANK() OVER (ORDER BY total_views DESC) AS view_rank
FROM tag_aggregates
ORDER BY total_views DESC
LIMIT 10
