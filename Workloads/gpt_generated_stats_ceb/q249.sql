WITH post_stats AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(score), 0) AS total_post_score,
        COALESCE(SUM(answercount), 0) AS total_answer_count,
        COALESCE(SUM(viewcount), 0) AS total_view_count
    FROM posts
    GROUP BY owneruserid
),
comment_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
vote_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_cast_count,
        COALESCE(SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvote_cast_count,
        COALESCE(SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvote_cast_count
    FROM votes
    GROUP BY userid
),
badge_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
posthistory_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS post_history_count
    FROM posthistory
    GROUP BY userid
),
link_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
tag_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS tag_count,
        COALESCE(SUM(t.count), 0) AS total_tag_uses
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_answer_count, 0) AS total_answer_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(v.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.post_history_count, 0) AS post_history_count,
    COALESCE(l.postlink_count, 0) AS postlink_count,
    COALESCE(ts.tag_count, 0) AS tag_count,
    COALESCE(ts.total_tag_uses, 0) AS total_tag_uses,
    CASE WHEN COALESCE(p.post_count, 0) = 0 THEN 0 ELSE COALESCE(p.total_post_score, 0) / p.post_count END AS avg_post_score,
    CASE WHEN COALESCE(c.comment_count, 0) = 0 THEN 0 ELSE CAST(u.upvotes AS double) / c.comment_count END AS upvotes_per_comment
FROM users u
LEFT JOIN post_stats p       ON p.user_id = u.id
LEFT JOIN comment_stats c    ON c.user_id = u.id
LEFT JOIN vote_stats v       ON v.user_id = u.id
LEFT JOIN badge_stats b      ON b.user_id = u.id
LEFT JOIN posthistory_stats ph ON ph.user_id = u.id
LEFT JOIN link_stats l       ON l.user_id = u.id
LEFT JOIN tag_stats ts       ON ts.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
