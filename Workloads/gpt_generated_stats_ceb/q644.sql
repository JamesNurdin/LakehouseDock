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
            SUM(COALESCE(bountyamount, 0)) AS bounty_sum
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
    user_links AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS link_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_history AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS history_count
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY ph.userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            SUM(t.count) AS tag_usage_sum
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.post_score_sum, 0) AS post_score_sum,
    COALESCE(p.post_view_sum, 0) AS post_view_sum,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.bounty_sum, 0) AS bounty_sum,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(l.link_count, 0) AS link_count,
    COALESCE(h.history_count, 0) AS history_count,
    COALESCE(t.tag_usage_sum, 0) AS tag_usage_sum,
    (COALESCE(p.post_score_sum, 0) + COALESCE(c.comment_score_sum, 0) + COALESCE(v.bounty_sum, 0)) AS total_contributions
FROM users u
LEFT JOIN user_posts p      ON p.user_id = u.id
LEFT JOIN user_comments c   ON c.user_id = u.id
LEFT JOIN user_votes v      ON v.user_id = u.id
LEFT JOIN user_badges b     ON b.user_id = u.id
LEFT JOIN user_links l      ON l.user_id = u.id
LEFT JOIN user_history h    ON h.user_id = u.id
LEFT JOIN user_tags t       ON t.user_id = u.id
ORDER BY total_contributions DESC
LIMIT 10
