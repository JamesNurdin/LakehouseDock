WITH user_info AS (
  SELECT
    id,
    reputation,
    creationdate,
    views,
    upvotes,
    downvotes
  FROM users
),
badge_agg AS (
  SELECT
    userid,
    COUNT(*) AS badge_count,
    MIN(date) AS first_badge_date,
    MAX(date) AS last_badge_date
  FROM badges
  GROUP BY userid
),
comment_agg AS (
  SELECT
    userid,
    COUNT(*) AS comment_count,
    AVG(score) AS avg_comment_score,
    MAX(creationdate) AS last_comment_date
  FROM comments
  GROUP BY userid
),
post_owned_agg AS (
  SELECT
    owneruserid,
    COUNT(*) AS owned_post_count,
    SUM(viewcount) AS total_views_owned,
    AVG(score) AS avg_owned_post_score,
    SUM(favoritecount) AS total_favorites_owned
  FROM posts
  GROUP BY owneruserid
),
post_edited_agg AS (
  SELECT
    lasteditoruserid,
    COUNT(*) AS edited_post_count,
    SUM(viewcount) AS total_views_edited,
    AVG(score) AS avg_edited_post_score
  FROM posts
  GROUP BY lasteditoruserid
),
posthistory_agg AS (
  SELECT
    userid,
    COUNT(*) AS posthistory_count,
    COUNT(DISTINCT postid) AS distinct_posts_affected
  FROM posthistory
  GROUP BY userid
)
SELECT
  ui.id AS user_id,
  ui.reputation,
  COALESCE(b.badge_count, 0) AS badge_count,
  b.first_badge_date,
  b.last_badge_date,
  COALESCE(c.comment_count, 0) AS comment_count,
  c.avg_comment_score,
  COALESCE(po.owned_post_count, 0) AS owned_post_count,
  po.total_views_owned,
  po.avg_owned_post_score,
  po.total_favorites_owned,
  COALESCE(pe.edited_post_count, 0) AS edited_post_count,
  pe.total_views_edited,
  pe.avg_edited_post_score,
  COALESCE(ph.posthistory_count, 0) AS posthistory_count,
  ph.distinct_posts_affected
FROM user_info ui
LEFT JOIN badge_agg b
  ON b.userid = ui.id
LEFT JOIN comment_agg c
  ON c.userid = ui.id
LEFT JOIN post_owned_agg po
  ON po.owneruserid = ui.id
LEFT JOIN post_edited_agg pe
  ON pe.lasteditoruserid = ui.id
LEFT JOIN posthistory_agg ph
  ON ph.userid = ui.id
ORDER BY ui.reputation DESC
LIMIT 100
