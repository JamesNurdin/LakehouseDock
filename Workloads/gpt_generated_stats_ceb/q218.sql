WITH
  posts_agg AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS total_posts_owned,
      SUM(p.score) AS total_score_of_owned_posts,
      AVG(p.score) AS avg_score_of_owned_posts,
      SUM(p.answercount) AS total_answercount,
      SUM(p.commentcount) AS total_commentcount,
      SUM(p.favoritecount) AS total_favoritecount,
      SUM(p.viewcount) AS total_viewcount
    FROM posts p
    GROUP BY p.owneruserid
  ),
  votes_cast_agg AS (
    SELECT
      v.userid AS user_id,
      COUNT(*) AS total_votes_cast,
      SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_cast,
      COUNT(DISTINCT v.postid) AS distinct_posts_voted
    FROM votes v
    GROUP BY v.userid
  ),
  votes_received_agg AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(v.id) AS total_votes_received,
      SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
  ),
  edit_agg AS (
    SELECT
      p.lasteditoruserid AS user_id,
      COUNT(*) AS total_posts_edited
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
  )
SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(p_agg.total_posts_owned, 0) AS total_posts_owned,
  COALESCE(p_agg.total_score_of_owned_posts, 0) AS total_score_of_owned_posts,
  COALESCE(p_agg.avg_score_of_owned_posts, 0) AS avg_score_of_owned_posts,
  COALESCE(p_agg.total_answercount, 0) AS total_answercount,
  COALESCE(p_agg.total_commentcount, 0) AS total_commentcount,
  COALESCE(p_agg.total_favoritecount, 0) AS total_favoritecount,
  COALESCE(p_agg.total_viewcount, 0) AS total_viewcount,
  COALESCE(vc_agg.total_votes_cast, 0) AS total_votes_cast,
  COALESCE(vc_agg.total_bounty_cast, 0) AS total_bounty_cast,
  COALESCE(vc_agg.distinct_posts_voted, 0) AS distinct_posts_voted,
  COALESCE(vr_agg.total_votes_received, 0) AS total_votes_received,
  COALESCE(vr_agg.total_bounty_received, 0) AS total_bounty_received,
  COALESCE(e_agg.total_posts_edited, 0) AS total_posts_edited
FROM users u
LEFT JOIN posts_agg p_agg ON u.id = p_agg.user_id
LEFT JOIN votes_cast_agg vc_agg ON u.id = vc_agg.user_id
LEFT JOIN votes_received_agg vr_agg ON u.id = vr_agg.user_id
LEFT JOIN edit_agg e_agg ON u.id = e_agg.user_id
ORDER BY total_score_of_owned_posts DESC
LIMIT 100
