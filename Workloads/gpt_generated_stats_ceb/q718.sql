WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS total_posts,
        SUM(CASE WHEN p.posttypeid = 1 THEN 1 ELSE 0 END) AS total_questions,
        SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers,
        SUM(p.viewcount) AS total_viewcount,
        AVG(p.score) AS avg_post_score,
        SUM(p.answercount) AS total_answer_count,
        SUM(p.commentcount) AS total_comment_count,
        SUM(p.favoritecount) AS total_favorite_count
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid,
        COUNT(*) AS total_comments,
        SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid,
        COUNT(*) AS total_votes,
        COUNT(DISTINCT v.postid) AS distinct_posts_voted,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_amount
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT
        b.userid,
        COUNT(*) AS total_badges
    FROM badges b
    GROUP BY b.userid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS distinct_tag_count,
        SUM(t."count") AS total_tag_usage
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_questions, 0) AS total_questions,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(uc.total_comments, 0) AS total_comments,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uv.total_votes, 0) AS total_votes,
    COALESCE(uv.distinct_posts_voted, 0) AS distinct_posts_voted,
    COALESCE(uv.upvote_count, 0) AS upvote_count,
    COALESCE(uv.downvote_count, 0) AS downvote_count,
    COALESCE(uv.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(ut.total_tag_usage, 0) AS total_tag_usage
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_tags ut ON ut.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
