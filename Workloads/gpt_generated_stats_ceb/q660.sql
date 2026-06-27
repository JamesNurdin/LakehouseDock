WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(score) AS post_score_sum,
        SUM(viewcount) AS post_view_sum,
        SUM(answercount) AS post_answer_sum,
        SUM(commentcount) AS post_comment_sum,
        SUM(favoritecount) AS post_favorite_sum
    FROM posts
    GROUP BY owneruserid
),
user_edits AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_posthistory_type_posts AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_type_post_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0) AS total_posts_owned,
    COALESCE(p.post_score_sum, 0) AS total_posts_score,
    COALESCE(p.post_view_sum, 0) AS total_posts_views,
    COALESCE(p.post_answer_sum, 0) AS total_posts_answers,
    COALESCE(p.post_comment_sum, 0) AS total_posts_comments,
    COALESCE(p.post_favorite_sum, 0) AS total_posts_favorites,
    COALESCE(e.edit_count, 0) AS total_posts_edited,
    COALESCE(c.comment_count, 0) AS total_comments_made,
    COALESCE(c.comment_score_sum, 0) AS total_comment_score,
    COALESCE(ph.posthistory_count, 0) AS total_posthistory_entries,
    COALESCE(pht.posthistory_type_post_count, 0) AS total_posthistory_type_posts,
    CASE WHEN COALESCE(p.post_count, 0) > 0
         THEN COALESCE(p.post_score_sum, 0) / COALESCE(p.post_count, 0)
         ELSE NULL
    END AS avg_post_score
FROM users u
LEFT JOIN user_posts p ON u.id = p.user_id
LEFT JOIN user_edits e ON u.id = e.user_id
LEFT JOIN user_comments c ON u.id = c.user_id
LEFT JOIN user_posthistory ph ON u.id = ph.user_id
LEFT JOIN user_posthistory_type_posts pht ON u.id = pht.user_id
WHERE u.reputation > 0
ORDER BY total_posts_score DESC
LIMIT 100
