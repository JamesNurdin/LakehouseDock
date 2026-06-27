WITH post_stats AS (
    SELECT
        posts.id AS post_id,
        posts.posttypeid,
        posts.score,
        posts.viewcount,
        posts.answercount,
        posts.favoritecount,
        COUNT(posthistory.id) AS history_count,
        MIN(posthistory.creationdate) AS first_history_date,
        MAX(posthistory.creationdate) AS last_history_date
    FROM posts
    LEFT JOIN posthistory
        ON posthistory.posthistorytypeid = posts.id
    WHERE posts.score >= 0
    GROUP BY posts.id,
             posts.posttypeid,
             posts.score,
             posts.viewcount,
             posts.answercount,
             posts.favoritecount
)
SELECT
    post_id,
    posttypeid,
    history_count,
    first_history_date,
    last_history_date,
    score,
    viewcount,
    answercount,
    favoritecount,
    RANK() OVER (PARTITION BY posttypeid ORDER BY history_count DESC) AS rank_within_type
FROM post_stats
ORDER BY posttypeid,
         rank_within_type
LIMIT 100
