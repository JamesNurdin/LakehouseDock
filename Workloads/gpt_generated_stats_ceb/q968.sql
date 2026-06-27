WITH
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(score) AS post_score_sum,
            SUM(viewcount) AS post_view_sum,
            SUM(answercount) AS post_answer_sum,
            SUM(commentcount) AS post_comment_sum,
            SUM(favoritecount) AS post_favorite_sum
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(score) AS comment_score_sum
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN bountyamount IS NOT NULL THEN bountyamount ELSE 0 END) AS bounty_sum
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posthistory AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    user_postlinks_outgoing AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlink_outgoing_count
        FROM posts p
        JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks_incoming AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlink_incoming_count
        FROM posts p
        JOIN postlinks pl ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.post_score_sum, 0) AS post_score_sum,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.bounty_sum, 0) AS bounty_sum,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(h.posthistory_count, 0) AS posthistory_count,
    COALESCE(pl_out.postlink_outgoing_count, 0) AS postlink_outgoing_count,
    COALESCE(pl_in.postlink_incoming_count, 0) AS postlink_incoming_count,
    (
        COALESCE(p.post_count, 0) +
        COALESCE(c.comment_count, 0) +
        COALESCE(v.vote_count, 0) +
        COALESCE(b.badge_count, 0) +
        COALESCE(h.posthistory_count, 0) +
        COALESCE(pl_out.postlink_outgoing_count, 0) +
        COALESCE(pl_in.postlink_incoming_count, 0)
    ) AS total_contributions
FROM users u
LEFT JOIN user_posts p        ON p.user_id = u.id
LEFT JOIN user_comments c     ON c.user_id = u.id
LEFT JOIN user_votes v        ON v.user_id = u.id
LEFT JOIN user_badges b       ON b.user_id = u.id
LEFT JOIN user_posthistory h  ON h.user_id = u.id
LEFT JOIN user_postlinks_outgoing pl_out ON pl_out.user_id = u.id
LEFT JOIN user_postlinks_incoming pl_in  ON pl_in.user_id = u.id
ORDER BY total_contributions DESC
LIMIT 10
