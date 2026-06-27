WITH post_details AS (
    SELECT
        p.id AS post_id,
        p.score AS post_score,
        p.creationdate AS post_creationdate,
        p.owneruserid,
        p.lasteditoruserid
    FROM posts p
),
owner_rep AS (
    SELECT
        pd.post_id,
        pd.post_score,
        pd.post_creationdate,
        u.reputation AS owner_reputation,
        pd.lasteditoruserid
    FROM post_details pd
    JOIN users u
        ON pd.owneruserid = u.id
),
last_editor_rep AS (
    SELECT
        od.post_id,
        od.post_score,
        od.post_creationdate,
        od.owner_reputation,
        le.reputation AS last_editor_reputation
    FROM owner_rep od
    LEFT JOIN users le
        ON od.lasteditoruserid = le.id
),
comment_stats AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_count,
        AVG(u.reputation) AS avg_commenter_reputation
    FROM comments c
    JOIN users u
        ON c.userid = u.id
    GROUP BY c.postid
),
vote_stats AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_count,
        AVG(u.reputation) AS avg_voter_reputation,
        SUM(v.bountyamount) AS total_bounty_amount,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes v
    JOIN users u
        ON v.userid = u.id
    GROUP BY v.postid
)
SELECT
    le.post_id,
    le.post_score,
    le.post_creationdate,
    le.owner_reputation,
    le.last_editor_reputation,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_commenter_reputation, 0) AS avg_commenter_reputation,
    COALESCE(vs.vote_count, 0) AS vote_count,
    COALESCE(vs.avg_voter_reputation, 0) AS avg_voter_reputation,
    COALESCE(vs.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(vs.upvote_count, 0) AS upvote_count,
    COALESCE(vs.downvote_count, 0) AS downvote_count
FROM last_editor_rep le
LEFT JOIN comment_stats cs
    ON le.post_id = cs.post_id
LEFT JOIN vote_stats vs
    ON le.post_id = vs.post_id
ORDER BY le.post_score DESC
LIMIT 10
