WITH
    user_info AS (
        SELECT id AS user_id,
               reputation
        FROM users
    ),
    user_posts AS (
        SELECT owneruserid AS user_id,
               COUNT(*) FILTER (WHERE posttypeid = 1) AS question_count,
               COUNT(*) FILTER (WHERE posttypeid = 2) AS answer_count,
               SUM(score) AS total_post_score,
               SUM(favoritecount) AS total_favorites
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT userid AS user_id,
               COUNT(*) AS comment_made_count
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT userid AS user_id,
               COUNT(*) FILTER (WHERE votetypeid = 2) AS upvote_given_count,
               COUNT(*) FILTER (WHERE votetypeid = 3) AS downvote_given_count
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT userid AS user_id,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    )
SELECT
    ui.user_id,
    ui.reputation,
    COALESCE(up.question_count, 0)        AS question_count,
    COALESCE(up.answer_count, 0)          AS answer_count,
    COALESCE(up.total_post_score, 0)      AS total_post_score,
    COALESCE(up.total_favorites, 0)       AS total_favorites,
    COALESCE(uc.comment_made_count, 0)    AS comment_made_count,
    COALESCE(uv.upvote_given_count, 0)    AS upvote_given_count,
    COALESCE(uv.downvote_given_count, 0)  AS downvote_given_count,
    COALESCE(ub.badge_count, 0)           AS badge_count,
    (COALESCE(up.total_post_score, 0) * 1.0) / NULLIF(COALESCE(up.question_count, 0) + COALESCE(up.answer_count, 0), 0) AS avg_score_per_post,
    ROW_NUMBER() OVER (ORDER BY COALESCE(up.total_post_score, 0) DESC) AS rank_by_score
FROM user_info ui
LEFT JOIN user_posts    up ON up.user_id = ui.user_id   -- posts.owneruserid = users.id
LEFT JOIN user_comments uc ON uc.user_id = ui.user_id   -- comments.userid = users.id
LEFT JOIN user_votes    uv ON uv.user_id = ui.user_id   -- votes.userid = users.id
LEFT JOIN user_badges   ub ON ub.user_id = ui.user_id   -- badges.userid = users.id
WHERE ui.reputation > 1000
ORDER BY rank_by_score
LIMIT 100
