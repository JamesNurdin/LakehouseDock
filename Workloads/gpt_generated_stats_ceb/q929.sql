WITH user_base AS (
    SELECT id AS user_id,
           reputation
    FROM users
),
user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS post_count,
           SUM(CASE WHEN posttypeid = 1 THEN 1 ELSE 0 END) AS question_count,
           SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
           COALESCE(SUM(score), 0) AS total_post_score,
           COALESCE(AVG(score), 0) AS avg_post_score,
           COALESCE(SUM(viewcount), 0) AS total_view_count,
           COALESCE(AVG(viewcount), 0) AS avg_view_count
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid AS user_id,
           COUNT(*) AS comment_count,
           COALESCE(SUM(score), 0) AS total_comment_score,
           COALESCE(AVG(score), 0) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT userid AS user_id,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
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
user_tag_excerpts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS tag_excerpt_count
    FROM tags t
    JOIN posts p ON p.id = t.excerptpostid
    GROUP BY p.owneruserid
),
user_post_links AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS post_link_count
    FROM postlinks pl
    JOIN posts p ON p.id = pl.postid
    GROUP BY p.owneruserid
)
SELECT
    ub.user_id,
    ub.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.question_count, 0) AS question_count,
    COALESCE(up.answer_count, 0) AS answer_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(up.avg_view_count, 0) AS avg_view_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.upvote_count, 0) AS upvote_count,
    COALESCE(uv.downvote_count, 0) AS downvote_count,
    COALESCE(ubg.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ut.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(ulp.post_link_count, 0) AS post_link_count,
    (ub.reputation
        + COALESCE(ubg.badge_count, 0) * 10
        + COALESCE(up.total_post_score, 0) * 2
        + COALESCE(uv.upvote_count, 0) * 1
        - COALESCE(uv.downvote_count, 0) * 2
        + COALESCE(ut.tag_excerpt_count, 0) * 5
        + COALESCE(ulp.post_link_count, 0) * 3) AS activity_score
FROM user_base ub
LEFT JOIN user_posts up ON up.user_id = ub.user_id
LEFT JOIN user_comments uc ON uc.user_id = ub.user_id
LEFT JOIN user_votes uv ON uv.user_id = ub.user_id
LEFT JOIN user_badges ubg ON ubg.user_id = ub.user_id
LEFT JOIN user_edits ue ON ue.user_id = ub.user_id
LEFT JOIN user_tag_excerpts ut ON ut.user_id = ub.user_id
LEFT JOIN user_post_links ulp ON ulp.user_id = ub.user_id
ORDER BY activity_score DESC
LIMIT 10
