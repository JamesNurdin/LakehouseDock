WITH
    badge_counts AS (
        SELECT u.id AS user_id,
               COUNT(b.id) AS badge_count
        FROM users u
        LEFT JOIN badges b ON b.userid = u.id
        GROUP BY u.id
    ),
    post_owned AS (
        SELECT p.owneruserid AS user_id,
               COUNT(p.id) AS post_owned_count,
               COALESCE(SUM(p.score), 0) AS post_owned_score_sum,
               COALESCE(SUM(p.viewcount), 0) AS post_owned_view_sum
        FROM posts p
        GROUP BY p.owneruserid
    ),
    post_edited AS (
        SELECT p.lasteditoruserid AS user_id,
               COUNT(p.id) AS post_edited_count
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    comment_made AS (
        SELECT c.userid AS user_id,
               COUNT(c.id) AS comment_made_count
        FROM comments c
        GROUP BY c.userid
    ),
    comment_received AS (
        SELECT p.owneruserid AS user_id,
               COUNT(c.id) AS comment_received_count
        FROM posts p
        JOIN comments c ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    vote_cast AS (
        SELECT v.userid AS user_id,
               COUNT(v.id) AS vote_cast_count
        FROM votes v
        GROUP BY v.userid
    ),
    vote_received AS (
        SELECT p.owneruserid AS user_id,
               COUNT(v.id) AS vote_received_count
        FROM posts p
        JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_count AS (
        SELECT ph.userid AS user_id,
               COUNT(ph.id) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    postlinks_source AS (
        SELECT p.owneruserid AS user_id,
               COUNT(pl.id) AS postlinks_source_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_target AS (
        SELECT p.owneruserid AS user_id,
               COUNT(pl.id) AS postlinks_target_count
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    tag_usage AS (
        SELECT p.owneruserid AS user_id,
               COUNT(t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(po.post_owned_count, 0) AS post_owned_count,
    COALESCE(po.post_owned_score_sum, 0) AS post_owned_score_sum,
    COALESCE(po.post_owned_view_sum, 0) AS post_owned_view_sum,
    COALESCE(pe.post_edited_count, 0) AS post_edited_count,
    COALESCE(cm.comment_made_count, 0) AS comment_made_count,
    COALESCE(cr.comment_received_count, 0) AS comment_received_count,
    COALESCE(vc.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vr.vote_received_count, 0) AS vote_received_count,
    COALESCE(phc.posthistory_count, 0) AS posthistory_count,
    COALESCE(pls.postlinks_source_count, 0) AS postlinks_source_count,
    COALESCE(plt.postlinks_target_count, 0) AS postlinks_target_count,
    COALESCE(tu.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN badge_counts bc ON bc.user_id = u.id
LEFT JOIN post_owned po ON po.user_id = u.id
LEFT JOIN post_edited pe ON pe.user_id = u.id
LEFT JOIN comment_made cm ON cm.user_id = u.id
LEFT JOIN comment_received cr ON cr.user_id = u.id
LEFT JOIN vote_cast vc ON vc.user_id = u.id
LEFT JOIN vote_received vr ON vr.user_id = u.id
LEFT JOIN posthistory_count phc ON phc.user_id = u.id
LEFT JOIN postlinks_source pls ON pls.user_id = u.id
LEFT JOIN postlinks_target plt ON plt.user_id = u.id
LEFT JOIN tag_usage tu ON tu.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
