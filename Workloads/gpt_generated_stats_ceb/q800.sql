WITH post_votes AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate AS post_creationdate,
        p.score AS post_score,
        p.viewcount,
        p.owneruserid,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.lasteditoruserid,
        v.id AS vote_id,
        v.votetypeid,
        v.creationdate AS vote_creationdate,
        v.userid AS voter_userid,
        v.bountyamount
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
)
SELECT
    pv.post_id,
    pv.posttypeid,
    pv.post_creationdate,
    pv.owneruserid,
    u_owner.reputation AS owner_reputation,
    pv.lasteditoruserid,
    u_editor.reputation AS editor_reputation,
    pv.post_score,
    pv.viewcount,
    pv.answercount,
    pv.commentcount,
    pv.favoritecount,
    COUNT(pv.vote_id) AS total_votes,
    SUM(pv.bountyamount) AS total_bounty,
    COUNT(DISTINCT pv.votetypeid) AS distinct_vote_types,
    AVG(u_voter.reputation) AS avg_voter_reputation,
    MIN(pv.vote_creationdate) AS earliest_vote,
    MAX(pv.vote_creationdate) AS latest_vote
FROM post_votes pv
LEFT JOIN users u_owner
    ON pv.owneruserid = u_owner.id
LEFT JOIN users u_editor
    ON pv.lasteditoruserid = u_editor.id
LEFT JOIN users u_voter
    ON pv.voter_userid = u_voter.id
GROUP BY
    pv.post_id,
    pv.posttypeid,
    pv.post_creationdate,
    pv.owneruserid,
    u_owner.reputation,
    pv.lasteditoruserid,
    u_editor.reputation,
    pv.post_score,
    pv.viewcount,
    pv.answercount,
    pv.commentcount,
    pv.favoritecount
ORDER BY pv.post_score DESC
LIMIT 100
