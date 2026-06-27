WITH comment_stats AS (
    SELECT
        c.postid,
        COUNT(*) AS comment_count,
        SUM(c.score) AS comment_score_sum,
        AVG(c.score) AS comment_score_avg,
        COUNT(DISTINCT c.userid) AS unique_commenter_count,
        AVG(u.reputation) AS avg_commenter_reputation
    FROM comments c
    JOIN users u ON c.userid = u.id
    GROUP BY c.postid
),
vote_stats AS (
    SELECT
        v.postid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(v.bountyamount) AS total_bounty_amount
    FROM votes v
    GROUP BY v.postid
),
edit_stats AS (
    SELECT
        ph.posthistorytypeid AS postid,
        COUNT(*) AS edit_count
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
    p.commentcount,
    p.favoritecount,
    owner.reputation AS owner_reputation,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(cs.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(cs.unique_commenter_count, 0) AS unique_commenter_count,
    COALESCE(cs.avg_commenter_reputation, 0) AS avg_commenter_reputation,
    COALESCE(vs.vote_count, 0) AS vote_count,
    COALESCE(vs.upvote_count, 0) AS upvote_count,
    COALESCE(vs.downvote_count, 0) AS downvote_count,
    COALESCE(vs.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(es.edit_count, 0) AS edit_count
FROM posts p
LEFT JOIN users owner ON p.owneruserid = owner.id
LEFT JOIN comment_stats cs ON cs.postid = p.id
LEFT JOIN vote_stats vs ON vs.postid = p.id
LEFT JOIN edit_stats es ON es.postid = p.id
ORDER BY p.score DESC
LIMIT 10
