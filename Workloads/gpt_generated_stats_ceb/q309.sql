WITH post_votes AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.owneruserid,
        p.lasteditoruserid,
        p.creationdate AS post_creationdate,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        COUNT(v.id) AS total_votes,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(CASE WHEN v.votetypeid = 8 THEN v.bountyamount ELSE 0 END) AS total_bounty_awarded
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY
        p.id,
        p.posttypeid,
        p.owneruserid,
        p.lasteditoruserid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount
)
SELECT
    pv.post_id,
    pv.posttypeid,
    pv.score,
    pv.viewcount,
    pv.answercount,
    pv.commentcount,
    pv.favoritecount,
    pv.total_votes,
    pv.upvote_count,
    pv.downvote_count,
    pv.total_bounty_awarded,
    owner_user.reputation AS owner_reputation,
    owner_user.creationdate AS owner_creationdate,
    editor_user.reputation AS editor_reputation,
    editor_user.creationdate AS editor_creationdate,
    RANK() OVER (PARTITION BY pv.posttypeid ORDER BY pv.total_votes DESC) AS rank_within_type
FROM post_votes pv
LEFT JOIN users owner_user ON pv.owneruserid = owner_user.id
LEFT JOIN users editor_user ON pv.lasteditoruserid = editor_user.id
ORDER BY pv.total_votes DESC
LIMIT 20
