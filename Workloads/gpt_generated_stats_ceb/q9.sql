WITH owner_stats AS (
  SELECT
    owneruserid,
    COUNT(*) AS owned_post_count,
    SUM(score) AS owned_total_score,
    AVG(score) AS owned_avg_score,
    SUM(viewcount) AS owned_total_views,
    SUM(answercount) AS owned_total_answers,
    SUM(commentcount) AS owned_total_comments,
    SUM(favoritecount) AS owned_total_favorites
  FROM posts
  GROUP BY owneruserid
),
editor_stats AS (
  SELECT
    lasteditoruserid,
    COUNT(*) AS edited_post_count,
    SUM(score) AS edited_total_score,
    AVG(score) AS edited_avg_score
  FROM posts
  GROUP BY lasteditoruserid
),
badge_stats AS (
  SELECT
    userid,
    COUNT(*) AS badge_count
  FROM badges
  GROUP BY userid
)
SELECT
  u.id,
  u.reputation,
  u.creationdate,
  u.views,
  u.upvotes,
  u.downvotes,
  COALESCE(os.owned_post_count, 0) AS owned_post_count,
  COALESCE(os.owned_total_score, 0) AS owned_total_score,
  COALESCE(os.owned_avg_score, 0) AS owned_avg_score,
  COALESCE(os.owned_total_views, 0) AS owned_total_views,
  COALESCE(os.owned_total_answers, 0) AS owned_total_answers,
  COALESCE(os.owned_total_comments, 0) AS owned_total_comments,
  COALESCE(os.owned_total_favorites, 0) AS owned_total_favorites,
  COALESCE(es.edited_post_count, 0) AS edited_post_count,
  COALESCE(es.edited_total_score, 0) AS edited_total_score,
  COALESCE(es.edited_avg_score, 0) AS edited_avg_score,
  COALESCE(bs.badge_count, 0) AS badge_count,
  ROW_NUMBER() OVER (ORDER BY COALESCE(os.owned_post_count, 0) DESC) AS user_rank
FROM users u
LEFT JOIN owner_stats os ON os.owneruserid = u.id
LEFT JOIN editor_stats es ON es.lasteditoruserid = u.id
LEFT JOIN badge_stats bs ON bs.userid = u.id
ORDER BY owned_post_count DESC
LIMIT 100
