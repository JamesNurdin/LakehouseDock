WITH user_posts AS (
    SELECT
        p.id AS post_id,
        p.owneruserid AS owner_user_id,
        p.lasteditoruserid AS editor_user_id,
        p.creationdate AS post_creationdate,
        p.score AS post_score
    FROM posts p
),
votes_cast AS (
    SELECT
        v.userid AS voter_user_id,
        COUNT(*) AS votes_cast
    FROM votes v
    GROUP BY v.userid
),
votes_received AS (
    SELECT
        up.owner_user_id AS user_id,
        COUNT(v.id) AS votes_received
    FROM votes v
    JOIN user_posts up ON v.postid = up.post_id
    GROUP BY up.owner_user_id
),
postlinks_owned AS (
    SELECT
        up.owner_user_id AS user_id,
        COUNT(DISTINCT pl.id) AS postlinks_count
    FROM postlinks pl
    JOIN user_posts up
        ON pl.postid = up.post_id OR pl.relatedpostid = up.post_id
    GROUP BY up.owner_user_id
),
posthistory_counts AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_actions
    FROM posthistory ph
    GROUP BY ph.userid
),
posthistory_by_owned_posts AS (
    SELECT
        up.owner_user_id AS user_id,
        COUNT(ph.id) AS posthistory_entries_for_owned_posts
    FROM posthistory ph
    JOIN user_posts up ON ph.posthistorytypeid = up.post_id
    GROUP BY up.owner_user_id
),
user_stats AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(DISTINCT up.post_id) FILTER (WHERE up.owner_user_id = u.id) AS total_posts_owned,
        COUNT(DISTINCT up.post_id) FILTER (WHERE up.editor_user_id = u.id) AS total_posts_edited,
        AVG(up.post_score) FILTER (WHERE up.owner_user_id = u.id) AS avg_score_owned,
        MIN(up.post_creationdate) FILTER (WHERE up.owner_user_id = u.id) AS earliest_owned_post_date
    FROM users u
    LEFT JOIN user_posts up
        ON up.owner_user_id = u.id OR up.editor_user_id = u.id
    GROUP BY u.id, u.reputation
)
SELECT
    us.user_id,
    us.reputation,
    us.total_posts_owned,
    us.total_posts_edited,
    COALESCE(vc.votes_cast, 0) AS total_votes_cast,
    COALESCE(vr.votes_received, 0) AS total_votes_received,
    COALESCE(plc.postlinks_count, 0) AS total_postlinks_involving_owned_posts,
    COALESCE(phc.posthistory_actions, 0) AS total_posthistory_actions,
    COALESCE(phb.posthistory_entries_for_owned_posts, 0) AS posthistory_entries_for_owned_posts,
    us.avg_score_owned,
    us.earliest_owned_post_date
FROM user_stats us
LEFT JOIN votes_cast vc ON vc.voter_user_id = us.user_id
LEFT JOIN votes_received vr ON vr.user_id = us.user_id
LEFT JOIN postlinks_owned plc ON plc.user_id = us.user_id
LEFT JOIN posthistory_counts phc ON phc.user_id = us.user_id
LEFT JOIN posthistory_by_owned_posts phb ON phb.user_id = us.user_id
ORDER BY us.total_posts_owned DESC
LIMIT 100
