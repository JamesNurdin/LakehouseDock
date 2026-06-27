WITH user_activity AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes,
        COALESCE(bc.badge_count, 0) AS badge_count,
        COALESCE(cc.comment_count, 0) AS comment_count,
        COALESCE(cc.total_comment_score, 0) AS total_comment_score,
        COALESCE(vc.vote_count, 0) AS vote_count,
        COALESCE(vc.total_bounty, 0) AS total_bounty,
        COALESCE(vtc.vote_type_1, 0) AS vote_type_1,
        COALESCE(vtc.vote_type_2, 0) AS vote_type_2,
        COALESCE(vtc.vote_type_3, 0) AS vote_type_3
    FROM users u
    LEFT JOIN (
        SELECT userid, COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ) bc
        ON bc.userid = u.id
    LEFT JOIN (
        SELECT userid,
               COUNT(*) AS comment_count,
               SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ) cc
        ON cc.userid = u.id
    LEFT JOIN (
        SELECT userid,
               COUNT(*) AS vote_count,
               SUM(bountyamount) AS total_bounty
        FROM votes
        GROUP BY userid
    ) vc
        ON vc.userid = u.id
    LEFT JOIN (
        SELECT userid,
               SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS vote_type_1,
               SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS vote_type_2,
               SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS vote_type_3
        FROM votes
        GROUP BY userid
    ) vtc
        ON vtc.userid = u.id
)
SELECT
    user_id,
    reputation,
    views,
    upvotes,
    downvotes,
    badge_count,
    comment_count,
    total_comment_score,
    vote_count,
    total_bounty,
    vote_type_1,
    vote_type_2,
    vote_type_3,
    (badge_count + comment_count + vote_count) AS total_activity,
    RANK() OVER (ORDER BY (badge_count + comment_count + vote_count) DESC) AS activity_rank
FROM user_activity
WHERE (badge_count + comment_count + vote_count) > 0
ORDER BY activity_rank
LIMIT 100
