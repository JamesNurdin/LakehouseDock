WITH user_base AS (
    SELECT id AS user_id,
           reputation
    FROM users
),

user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           SUM(viewcount) AS total_post_views,
           SUM(answercount) AS total_answer_count,
           SUM(commentcount) AS total_comment_on_posts,
           AVG(score) AS avg_post_score
    FROM posts
    GROUP BY owneruserid
),

user_comments AS (
    SELECT userid AS user_id,
           COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),

user_votes AS (
    SELECT userid AS user_id,
           COUNT(*) AS vote_count,
           COUNT(CASE WHEN votetypeid = 1 THEN 1 END) AS upvote_cast,
           COUNT(CASE WHEN votetypeid = 2 THEN 1 END) AS downvote_cast
    FROM votes
    GROUP BY userid
),

user_badges AS (
    SELECT userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),

user_edits AS (
    SELECT userid AS user_id,
           COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
),

user_self_edits AS (
    SELECT u.id AS user_id,
           COUNT(*) AS self_edit_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    JOIN users u ON ph.userid = u.id
    WHERE p.owneruserid = u.id
    GROUP BY u.id
),

user_postlinks AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS postlink_count
    FROM posts p
    JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
),

user_tags AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS tag_count,
           SUM(t.count) AS tag_total_usage
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)

SELECT ub.user_id,
       ub.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.total_post_views, 0) AS total_post_views,
       COALESCE(up.total_answer_count, 0) AS total_answer_count,
       COALESCE(up.total_comment_on_posts, 0) AS total_comment_on_posts,
       COALESCE(up.avg_post_score, 0) AS avg_post_score,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uv.vote_count, 0) AS vote_count,
       COALESCE(uv.upvote_cast, 0) AS upvote_cast,
       COALESCE(uv.downvote_cast, 0) AS downvote_cast,
       COALESCE(ubad.badge_count, 0) AS badge_count,
       COALESCE(ue.edit_count, 0) AS edit_count,
       COALESCE(ues.self_edit_count, 0) AS self_edit_count,
       COALESCE(upk.postlink_count, 0) AS postlink_count,
       COALESCE(ut.tag_count, 0) AS tag_count,
       COALESCE(ut.tag_total_usage, 0) AS tag_total_usage
FROM user_base ub
LEFT JOIN user_posts up ON up.user_id = ub.user_id
LEFT JOIN user_comments uc ON uc.user_id = ub.user_id
LEFT JOIN user_votes uv ON uv.user_id = ub.user_id
LEFT JOIN user_badges ubad ON ubad.user_id = ub.user_id
LEFT JOIN user_edits ue ON ue.user_id = ub.user_id
LEFT JOIN user_self_edits ues ON ues.user_id = ub.user_id
LEFT JOIN user_postlinks upk ON upk.user_id = ub.user_id
LEFT JOIN user_tags ut ON ut.user_id = ub.user_id
ORDER BY ub.reputation DESC
LIMIT 100
