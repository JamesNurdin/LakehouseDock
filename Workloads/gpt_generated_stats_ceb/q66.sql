WITH badge_counts AS (
    SELECT userid,
           COUNT(id) AS badge_cnt
    FROM badges
    GROUP BY userid
),
post_stats AS (
    SELECT owneruserid,
           COUNT(id) AS post_cnt,
           SUM(score) AS total_score,
           AVG(score) AS avg_score,
           SUM(viewcount) AS total_viewcount,
           SUM(answercount) AS total_answercount,
           SUM(favoritecount) AS total_favoritecount,
           SUM(commentcount) AS total_commentcount
    FROM posts
    GROUP BY owneruserid
),
vote_cast_stats AS (
    SELECT userid,
           COUNT(id) AS vote_cnt,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cnt,
           SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cnt,
           SUM(bountyamount) AS total_bounty
    FROM votes
    GROUP BY userid
),
vote_received_stats AS (
    SELECT p.owneruserid AS owneruserid,
           COUNT(v.id) AS vote_received_cnt,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_received_cnt,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_received_cnt
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
edited_post_counts AS (
    SELECT lasteditoruserid,
           COUNT(DISTINCT id) AS edited_post_cnt
    FROM posts
    GROUP BY lasteditoruserid
)
SELECT u.id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(bc.badge_cnt, 0) AS badge_cnt,
       COALESCE(ps.post_cnt, 0) AS post_cnt,
       COALESCE(ps.total_score, 0) AS total_score,
       COALESCE(ps.avg_score, 0) AS avg_score,
       COALESCE(ps.total_viewcount, 0) AS total_viewcount,
       COALESCE(ps.total_answercount, 0) AS total_answercount,
       COALESCE(ps.total_favoritecount, 0) AS total_favoritecount,
       COALESCE(ps.total_commentcount, 0) AS total_commentcount,
       COALESCE(vc.vote_cnt, 0) AS vote_cnt,
       COALESCE(vc.upvote_cnt, 0) AS upvote_cnt,
       COALESCE(vc.downvote_cnt, 0) AS downvote_cnt,
       COALESCE(vc.total_bounty, 0) AS total_bounty,
       COALESCE(vr.vote_received_cnt, 0) AS vote_received_cnt,
       COALESCE(vr.upvote_received_cnt, 0) AS upvote_received_cnt,
       COALESCE(vr.downvote_received_cnt, 0) AS downvote_received_cnt,
       COALESCE(ep.edited_post_cnt, 0) AS edited_post_cnt
FROM users u
LEFT JOIN badge_counts bc ON bc.userid = u.id
LEFT JOIN post_stats ps ON ps.owneruserid = u.id
LEFT JOIN vote_cast_stats vc ON vc.userid = u.id
LEFT JOIN vote_received_stats vr ON vr.owneruserid = u.id
LEFT JOIN edited_post_counts ep ON ep.lasteditoruserid = u.id
ORDER BY total_score DESC
LIMIT 100
