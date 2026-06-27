WITH
    user_base AS (
        SELECT id, reputation
        FROM users
    ),
    badge_counts AS (
        SELECT userid, COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    comment_counts AS (
        SELECT userid, COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    posthistory_counts AS (
        SELECT userid, COUNT(*) AS post_history_count
        FROM posthistory
        GROUP BY userid
    ),
    votes_cast_counts AS (
        SELECT userid, COUNT(*) AS votes_cast_count
        FROM votes
        GROUP BY userid
    ),
    post_aggregates AS (
        SELECT owneruserid AS user_id,
               COUNT(*) AS post_count,
               COALESCE(SUM(score), 0) AS total_post_score,
               COALESCE(AVG(score), 0) AS avg_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    votes_received_counts AS (
        SELECT p.owneruserid AS user_id,
               COUNT(v.id) AS vote_received_count
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    postlink_counts AS (
        SELECT p.owneruserid AS user_id,
               COUNT(pl.id) AS post_link_count
        FROM posts p
        LEFT JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    tag_counts AS (
        SELECT p.owneruserid AS user_id,
               COALESCE(SUM(t.count), 0) AS total_tag_count
        FROM posts p
        LEFT JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ub.id AS user_id,
    ub.reputation,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(phc.post_history_count, 0) AS post_history_count,
    COALESCE(vcc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(pa.total_post_score, 0) AS total_post_score,
    COALESCE(pa.avg_post_score, 0) AS avg_post_score,
    COALESCE(vrc.vote_received_count, 0) AS vote_received_count,
    COALESCE(plc.post_link_count, 0) AS post_link_count,
    COALESCE(tc.total_tag_count, 0) AS total_tag_count
FROM user_base ub
LEFT JOIN badge_counts bc      ON bc.userid = ub.id
LEFT JOIN comment_counts cc    ON cc.userid = ub.id
LEFT JOIN posthistory_counts phc ON phc.userid = ub.id
LEFT JOIN votes_cast_counts vcc   ON vcc.userid = ub.id
LEFT JOIN post_aggregates pa      ON pa.user_id = ub.id
LEFT JOIN votes_received_counts vrc ON vrc.user_id = ub.id
LEFT JOIN postlink_counts plc      ON plc.user_id = ub.id
LEFT JOIN tag_counts tc            ON tc.user_id = ub.id
ORDER BY total_post_score DESC
LIMIT 10
