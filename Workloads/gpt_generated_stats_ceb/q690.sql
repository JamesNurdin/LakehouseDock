WITH user_base AS (
    SELECT id,
           reputation
    FROM users
),
post_stats AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(AVG(p.score), 0) AS avg_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
           COALESCE(SUM(p.answercount), 0) AS total_answercount,
           COALESCE(SUM(p.commentcount), 0) AS total_commentcount,
           COALESCE(SUM(p.favoritecount), 0) AS total_favoritecount
    FROM posts p
    GROUP BY p.owneruserid
),
comment_stats AS (
    SELECT c.userid AS user_id,
           COUNT(*) AS comment_count,
           COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
badge_stats AS (
    SELECT b.userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
vote_cast_stats AS (
    SELECT v.userid AS user_id,
           COUNT(*) AS votes_cast_count
    FROM votes v
    GROUP BY v.userid
),
vote_received_stats AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS votes_received_count
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
tag_stats AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
posthistory_stats AS (
    SELECT ph.userid AS user_id,
           COUNT(*) AS posthistory_event_count
    FROM posthistory ph
    GROUP BY ph.userid
),
postlinks_stats AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT ub.id AS user_id,
       ub.reputation,
       COALESCE(ps.post_count, 0) AS post_count,
       COALESCE(ps.total_post_score, 0) AS total_post_score,
       COALESCE(ps.avg_post_score, 0) AS avg_post_score,
       COALESCE(ps.total_viewcount, 0) AS total_viewcount,
       COALESCE(ps.total_answercount, 0) AS total_answercount,
       COALESCE(ps.total_commentcount, 0) AS total_commentcount,
       COALESCE(ps.total_favoritecount, 0) AS total_favoritecount,
       COALESCE(cs.comment_count, 0) AS comment_count,
       COALESCE(cs.total_comment_score, 0) AS total_comment_score,
       COALESCE(bs.badge_count, 0) AS badge_count,
       COALESCE(vcs.votes_cast_count, 0) AS votes_cast_count,
       COALESCE(vrs.votes_received_count, 0) AS votes_received_count,
       COALESCE(ts.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(phs.posthistory_event_count, 0) AS posthistory_event_count,
       COALESCE(pls.postlink_count, 0) AS postlink_count
FROM user_base ub
LEFT JOIN post_stats ps ON ps.user_id = ub.id
LEFT JOIN comment_stats cs ON cs.user_id = ub.id
LEFT JOIN badge_stats bs ON bs.user_id = ub.id
LEFT JOIN vote_cast_stats vcs ON vcs.user_id = ub.id
LEFT JOIN vote_received_stats vrs ON vrs.user_id = ub.id
LEFT JOIN tag_stats ts ON ts.user_id = ub.id
LEFT JOIN posthistory_stats phs ON phs.user_id = ub.id
LEFT JOIN postlinks_stats pls ON pls.user_id = ub.id
ORDER BY ub.reputation DESC
LIMIT 100
