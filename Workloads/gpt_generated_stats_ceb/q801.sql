WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS total_posts,
        SUM(p.answercount) AS total_answers,
        AVG(p.score) AS avg_post_score,
        MAX(p.creationdate) AS last_post_creationdate
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
post_comments AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(c.id) AS total_comments_on_posts,
        AVG(c.score) AS avg_comment_score
    FROM posts p
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY p.owneruserid
),
post_votes AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS total_votes_on_posts,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS total_upvotes,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS total_downvotes,
        SUM(v.bountyamount) AS total_bounty_amount
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(pc.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(pc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(pv.total_votes_on_posts, 0) AS total_votes_on_posts,
    COALESCE(pv.total_upvotes, 0) AS total_upvotes,
    COALESCE(pv.total_downvotes, 0) AS total_downvotes,
    COALESCE(pv.total_bounty_amount, 0) AS total_bounty_amount,
    up.last_post_creationdate
FROM users u
LEFT JOIN user_posts up
    ON up.user_id = u.id
LEFT JOIN post_comments pc
    ON pc.user_id = u.id
LEFT JOIN post_votes pv
    ON pv.user_id = u.id
ORDER BY total_posts DESC
LIMIT 100
