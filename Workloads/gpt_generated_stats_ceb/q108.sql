/*
  User‑level activity summary – shows reputation and a set of aggregated metrics
  (badges earned, posts owned, questions/answers, post score & views, comments made,
   votes cast, votes received on owned posts, and tag‑excerpt contributions).
  All joins follow the allowed join rules and no date literals are used.
*/
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(b.badge_count, 0)            AS badge_count,
    COALESCE(p.post_count, 0)             AS post_count,
    COALESCE(p.question_count, 0)        AS question_count,
    COALESCE(p.answer_count, 0)          AS answer_count,
    COALESCE(p.total_score, 0)           AS total_post_score,
    COALESCE(p.total_viewcount, 0)       AS total_viewcount,
    COALESCE(c.comment_count, 0)         AS comment_count,
    COALESCE(vc.vote_cast_count, 0)      AS vote_cast_count,
    COALESCE(vr.vote_received_count, 0)  AS vote_received_count,
    COALESCE(t.tag_excerpt_count, 0)     AS tag_excerpt_count
FROM users u
LEFT JOIN (
    SELECT userid, COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
) b ON b.userid = u.id
LEFT JOIN (
    SELECT owneruserid,
           COUNT(*) AS post_count,
           SUM(CASE WHEN posttypeid = 1 THEN 1 ELSE 0 END) AS question_count,
           SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
           SUM(score) AS total_score,
           SUM(viewcount) AS total_viewcount
    FROM posts
    GROUP BY owneruserid
) p ON p.owneruserid = u.id
LEFT JOIN (
    SELECT userid, COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
) c ON c.userid = u.id
LEFT JOIN (
    SELECT userid, COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
) vc ON vc.userid = u.id
LEFT JOIN (
    SELECT p.owneruserid AS user_id, COUNT(*) AS vote_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
) vr ON vr.user_id = u.id
LEFT JOIN (
    SELECT p.owneruserid AS user_id, COUNT(*) AS tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
) t ON t.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 20
