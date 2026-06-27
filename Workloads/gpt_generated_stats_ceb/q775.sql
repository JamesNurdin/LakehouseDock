WITH
  user_base AS (
    SELECT id AS user_id, reputation
    FROM users
  ),
  badge_counts AS (
    SELECT userid AS user_id, COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
  ),
  post_counts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS post_owned_count,
           AVG(score) AS avg_post_score
    FROM posts
    GROUP BY owneruserid
  ),
  edited_posts_counts AS (
    SELECT lasteditoruserid AS user_id, COUNT(*) AS edited_posts_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
  ),
  comment_counts AS (
    SELECT userid AS user_id, COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
  ),
  vote_cast_counts AS (
    SELECT userid AS user_id, COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
  ),
  posthistory_user_counts AS (
    SELECT userid AS user_id, COUNT(*) AS posthistory_user_count
    FROM posthistory
    GROUP BY userid
  ),
  posthistory_owned_counts AS (
    SELECT p.owneruserid AS user_id, COUNT(*) AS posthistory_owned_count
    FROM posthistory ph
    JOIN posts p
      ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
  )
SELECT
  ub.user_id,
  ub.reputation,
  COALESCE(bc.badge_count, 0) AS badge_count,
  COALESCE(pc.post_owned_count, 0) AS post_owned_count,
  pc.avg_post_score,
  COALESCE(epc.edited_posts_count, 0) AS edited_posts_count,
  COALESCE(cc.comment_count, 0) AS comment_count,
  COALESCE(vc.vote_cast_count, 0) AS vote_cast_count,
  COALESCE(phc.posthistory_user_count, 0) AS posthistory_user_count,
  COALESCE(phoc.posthistory_owned_count, 0) AS posthistory_owned_count,
  (COALESCE(bc.badge_count, 0) * 10
   + COALESCE(pc.post_owned_count, 0) * 5
   + COALESCE(epc.edited_posts_count, 0) * 3
   + COALESCE(cc.comment_count, 0) * 2
   + COALESCE(vc.vote_cast_count, 0)
   + COALESCE(phc.posthistory_user_count, 0) * 3
   + COALESCE(phoc.posthistory_owned_count, 0) * 4) AS activity_score
FROM user_base ub
LEFT JOIN badge_counts bc ON bc.user_id = ub.user_id
LEFT JOIN post_counts pc ON pc.user_id = ub.user_id
LEFT JOIN edited_posts_counts epc ON epc.user_id = ub.user_id
LEFT JOIN comment_counts cc ON cc.user_id = ub.user_id
LEFT JOIN vote_cast_counts vc ON vc.user_id = ub.user_id
LEFT JOIN posthistory_user_counts phc ON phc.user_id = ub.user_id
LEFT JOIN posthistory_owned_counts phoc ON phoc.user_id = ub.user_id
WHERE COALESCE(pc.post_owned_count, 0) > 0
ORDER BY activity_score DESC
LIMIT 20
