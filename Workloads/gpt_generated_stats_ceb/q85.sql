WITH comment_stats AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_count,
        SUM(c.score) AS comment_score_sum,
        AVG(c.score) AS comment_score_avg
    FROM comments c
    GROUP BY c.postid
),
vote_stats AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN v.bountyamount ELSE 0 END) AS bounty_total
    FROM votes v
    GROUP BY v.postid
),
posthistory_stats AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.answercount,
    p.commentcount AS post_comment_count,
    p.favoritecount,
    u.id AS owner_user_id,
    u.reputation AS owner_reputation,
    cs.comment_count,
    cs.comment_score_sum,
    cs.comment_score_avg,
    vs.vote_count,
    vs.upvote_count,
    vs.downvote_count,
    vs.bounty_total,
    phs.posthistory_count
FROM posts p
LEFT JOIN users u
    ON p.owneruserid = u.id
LEFT JOIN comment_stats cs
    ON cs.post_id = p.id
LEFT JOIN vote_stats vs
    ON vs.post_id = p.id
LEFT JOIN posthistory_stats phs
    ON phs.post_id = p.id
WHERE p.posttypeid = 1
ORDER BY p.creationdate DESC
LIMIT 100
