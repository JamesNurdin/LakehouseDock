WITH post_votes AS (
    SELECT
        v.postid,
        COUNT(*) AS total_votes,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 WHEN v.votetypeid = 3 THEN -1 ELSE 0 END) AS net_score,
        SUM(v.bountyamount) AS total_bounty,
        COUNT(DISTINCT v.userid) AS distinct_voters
    FROM votes v
    GROUP BY v.postid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS original_score,
    p.viewcount,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    o.id AS owner_id,
    o.reputation AS owner_reputation,
    e.id AS editor_id,
    e.reputation AS editor_reputation,
    pv.total_votes,
    pv.net_score,
    pv.total_bounty,
    pv.distinct_voters
FROM posts p
LEFT JOIN post_votes pv ON pv.postid = p.id
LEFT JOIN users o ON p.owneruserid = o.id
LEFT JOIN users e ON p.lasteditoruserid = e.id
ORDER BY pv.net_score DESC
LIMIT 10
