WITH user_votes_received AS (
    SELECT
        p.owneruserid AS owner_user_id,
        COUNT(v.id) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
    FROM posts p
    JOIN votes v
        ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_cast AS (
    SELECT
        v.userid AS voter_user_id,
        COUNT(v.id) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
),
user_edits AS (
    SELECT
        ph.userid AS editor_user_id,
        COUNT(ph.id) AS edit_actions,
        COUNT(DISTINCT ph.postid) AS distinct_posts_edited
    FROM posthistory ph
    GROUP BY ph.userid
),
last_editor_stats AS (
    SELECT
        p.lasteditoruserid AS last_editor_user_id,
        COUNT(p.id) AS last_edits
    FROM posts p
    GROUP BY p.lasteditoruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COUNT(p.id) AS posts_owned,
    COALESCE(SUM(p.score), 0) AS total_post_score,
    COALESCE(SUM(p.viewcount), 0) AS total_post_views,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(e.edit_actions, 0) AS edit_actions,
    COALESCE(e.distinct_posts_edited, 0) AS distinct_posts_edited,
    COALESCE(le.last_edits, 0) AS last_editor_actions
FROM users u
LEFT JOIN posts p
    ON p.owneruserid = u.id
LEFT JOIN user_votes_received vr
    ON vr.owner_user_id = u.id
LEFT JOIN user_votes_cast vc
    ON vc.voter_user_id = u.id
LEFT JOIN user_edits e
    ON e.editor_user_id = u.id
LEFT JOIN last_editor_stats le
    ON le.last_editor_user_id = u.id
GROUP BY
    u.id,
    u.reputation,
    vr.votes_received,
    vr.upvotes_received,
    vr.downvotes_received,
    vc.votes_cast,
    vc.upvotes_cast,
    vc.downvotes_cast,
    e.edit_actions,
    e.distinct_posts_edited,
    le.last_edits
ORDER BY total_post_score DESC
LIMIT 100
