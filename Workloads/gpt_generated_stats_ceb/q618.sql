WITH vote_agg AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_given
    FROM votes v
    GROUP BY v.postid
),
edit_agg AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS edit_count,
        COUNT(DISTINCT ph.userid) AS distinct_editor_count
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate AS post_creationdate,
    p.score,
    p.viewcount,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    owner_user.id AS owner_user_id,
    owner_user.reputation AS owner_reputation,
    editor_user.id AS last_editor_user_id,
    editor_user.reputation AS last_editor_reputation,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.upvote_count, 0) AS upvote_count,
    COALESCE(v.downvote_count, 0) AS downvote_count,
    COALESCE(v.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(e.distinct_editor_count, 0) AS distinct_editor_count,
    (p.score + COALESCE(v.upvote_count, 0) - COALESCE(v.downvote_count, 0)) AS net_score
FROM posts p
LEFT JOIN users owner_user
    ON p.owneruserid = owner_user.id
LEFT JOIN users editor_user
    ON p.lasteditoruserid = editor_user.id
LEFT JOIN vote_agg v
    ON v.post_id = p.id
LEFT JOIN edit_agg e
    ON e.post_id = p.id
ORDER BY net_score DESC
LIMIT 50
