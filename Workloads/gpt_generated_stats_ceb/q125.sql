WITH user_posts AS (
    SELECT
        u.id,
        u.reputation,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.answercount), 0) AS total_answer_count,
        COALESCE(SUM(p.commentcount), 0) AS total_comment_on_posts
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_votes_cast AS (
    SELECT
        v.userid,
        COUNT(v.id) AS votes_cast,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_cast
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT
        b.userid,
        COUNT(b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid,
        COUNT(v.id) AS votes_received,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
    FROM posts p
    JOIN votes v
        ON v.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    up.id AS user_id,
    up.reputation,
    up.post_count,
    up.total_post_score,
    up.total_answer_count,
    up.total_comment_on_posts,
    COALESCE(vcast.votes_cast, 0) AS votes_cast,
    COALESCE(vcast.total_bounty_cast, 0) AS total_bounty_cast,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(vrec.votes_received, 0) AS votes_received,
    COALESCE(vrec.total_bounty_received, 0) AS total_bounty_received
FROM user_posts up
LEFT JOIN user_votes_cast vcast
    ON up.id = vcast.userid
LEFT JOIN user_badges ub
    ON up.id = ub.userid
LEFT JOIN user_votes_received vrec
    ON up.id = vrec.owneruserid
ORDER BY up.total_post_score DESC
LIMIT 10
