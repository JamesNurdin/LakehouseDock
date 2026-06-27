WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS total_posts,
        SUM(CASE WHEN p.posttypeid = 1 THEN 1 ELSE 0 END) AS total_questions,
        SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers,
        COALESCE(SUM(p.score), 0) AS total_score,
        COALESCE(AVG(p.score), 0) AS avg_score,
        COALESCE(SUM(p.viewcount), 0) AS total_views,
        COALESCE(SUM(p.answercount), 0) AS total_answercount,
        COALESCE(SUM(p.commentcount), 0) AS total_commentcount,
        COALESCE(SUM(p.favoritecount), 0) AS total_favoritecount
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(v.id) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes_cast,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_given
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes_received,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
    FROM votes v
    JOIN posts p
        ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_postlinks AS (
    SELECT DISTINCT
        p.owneruserid AS user_id,
        pl.id AS postlink_id
    FROM postlinks pl
    JOIN posts p
        ON pl.postid = p.id
    UNION
    SELECT DISTINCT
        p.owneruserid AS user_id,
        pl.id AS postlink_id
    FROM postlinks pl
    JOIN posts p
        ON pl.relatedpostid = p.id
),
aggregated_postlinks AS (
    SELECT
        user_id,
        COUNT(postlink_id) AS total_postlinks
    FROM user_postlinks
    GROUP BY user_id
)
SELECT
    up.user_id,
    up.reputation,
    up.total_posts,
    up.total_questions,
    up.total_answers,
    up.total_score,
    up.avg_score,
    up.total_views,
    up.total_answercount,
    up.total_commentcount,
    up.total_favoritecount,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.up_votes_cast, 0) AS up_votes_cast,
    COALESCE(uvc.down_votes_cast, 0) AS down_votes_cast,
    COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.up_votes_received, 0) AS up_votes_received,
    COALESCE(uvr.down_votes_received, 0) AS down_votes_received,
    COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(ap.total_postlinks, 0) AS postlinks_count,
    RANK() OVER (ORDER BY up.total_score DESC) AS score_rank
FROM user_posts up
LEFT JOIN user_votes_cast uvc
    ON up.user_id = uvc.user_id
LEFT JOIN user_votes_received uvr
    ON up.user_id = uvr.user_id
LEFT JOIN aggregated_postlinks ap
    ON up.user_id = ap.user_id
ORDER BY up.total_score DESC
LIMIT 100
