WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        p.id AS post_id,
        p.score AS post_score,
        p.viewcount AS post_viewcount,
        p.creationdate AS post_creationdate
    FROM users u
    JOIN posts p ON p.owneruserid = u.id
),
post_votes_received AS (
    SELECT
        v.postid,
        COUNT(*) AS votes_received,
        SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END) AS bounty_received
    FROM votes v
    GROUP BY v.postid
),
user_votes_cast AS (
    SELECT
        v.userid AS voter_user_id,
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END) AS bounty_given
    FROM votes v
    GROUP BY v.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COUNT(DISTINCT up.post_id) AS posts_owned,
    SUM(up.post_score) AS total_post_score,
    AVG(up.post_score) AS avg_post_score,
    SUM(COALESCE(pvr.votes_received, 0)) AS total_votes_received,
    SUM(COALESCE(pvr.bounty_received, 0)) AS total_bounty_received,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.bounty_given, 0) AS bounty_given,
    AVG(up.post_viewcount) AS avg_post_viewcount
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN post_votes_received pvr ON pvr.postid = up.post_id
LEFT JOIN user_votes_cast uvc ON uvc.voter_user_id = u.id
GROUP BY u.id, u.reputation, uvc.votes_cast, uvc.bounty_given
ORDER BY total_post_score DESC
LIMIT 20
