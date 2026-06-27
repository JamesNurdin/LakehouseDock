WITH
    users_base AS (
        SELECT id, reputation
        FROM users
    ),
    badge_counts AS (
        SELECT userid, COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    post_counts AS (
        SELECT owneruserid AS userid,
               COUNT(*) AS post_count,
               SUM(score) AS total_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    comment_counts AS (
        SELECT userid,
               COUNT(*) AS comment_count,
               SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    vote_cast_counts AS (
        SELECT userid, COUNT(*) AS votes_cast_count
        FROM votes
        GROUP BY userid
    ),
    vote_received_counts AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS votes_received_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    tag_counts AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_counts AS (
        SELECT userid, COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    postlink_counts AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    edit_counts AS (
        SELECT lasteditoruserid AS userid,
               COUNT(*) AS edit_count
        FROM posts
        GROUP BY lasteditoruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(pl.postlink_count, 0) AS postlink_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    (
        COALESCE(b.badge_count, 0) +
        COALESCE(p.post_count, 0) +
        COALESCE(c.comment_count, 0) +
        COALESCE(vc.votes_cast_count, 0) +
        COALESCE(vr.votes_received_count, 0) +
        COALESCE(t.tag_count, 0) +
        COALESCE(ph.posthistory_count, 0) +
        COALESCE(pl.postlink_count, 0) +
        COALESCE(e.edit_count, 0)
    ) AS total_contributions
FROM users_base u
LEFT JOIN badge_counts b ON b.userid = u.id
LEFT JOIN post_counts p ON p.userid = u.id
LEFT JOIN comment_counts c ON c.userid = u.id
LEFT JOIN vote_cast_counts vc ON vc.userid = u.id
LEFT JOIN vote_received_counts vr ON vr.userid = u.id
LEFT JOIN tag_counts t ON t.userid = u.id
LEFT JOIN posthistory_counts ph ON ph.userid = u.id
LEFT JOIN postlink_counts pl ON pl.userid = u.id
LEFT JOIN edit_counts e ON e.userid = u.id
ORDER BY total_contributions DESC
LIMIT 10
