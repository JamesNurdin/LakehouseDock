WITH
  owner_posts AS (
    SELECT
      owneruserid AS user_id,
      COUNT(*) AS posts_owned,
      SUM(score) AS total_post_score,
      SUM(viewcount) AS total_post_views
    FROM posts
    GROUP BY owneruserid
  ),
  editor_posts AS (
    SELECT
      lasteditoruserid AS user_id,
      COUNT(*) AS posts_edited
    FROM posts
    GROUP BY lasteditoruserid
  ),
  user_comments AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS comments_made,
      AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
  ),
  user_votes AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS votes_cast,
      SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
      SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes
    GROUP BY userid
  ),
  user_badges AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS badges_earned
    FROM badges
    GROUP BY userid
  ),
  user_posthistory AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS posthistory_events
    FROM posthistory
    GROUP BY userid
  ),
  tag_counts AS (
    SELECT
      p.owneruserid AS user_id,
      SUM(t.count) AS tag_count_sum
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
  ),
  post_links AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS outgoing_links
    FROM postlinks pl_tbl
    JOIN posts p ON pl_tbl.postid = p.id
    GROUP BY p.owneruserid
  )
SELECT
  u.id AS user_id,
  u.reputation,
  u.creationdate,
  COALESCE(op.posts_owned, 0) AS posts_owned,
  COALESCE(op.total_post_score, 0) AS total_post_score,
  COALESCE(op.total_post_views, 0) AS total_post_views,
  COALESCE(ep.posts_edited, 0) AS posts_edited,
  COALESCE(uc.comments_made, 0) AS comments_made,
  COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
  COALESCE(uv.votes_cast, 0) AS votes_cast,
  COALESCE(uv.upvotes_cast, 0) AS upvotes_cast,
  COALESCE(uv.downvotes_cast, 0) AS downvotes_cast,
  COALESCE(ub.badges_earned, 0) AS badges_earned,
  COALESCE(uph.posthistory_events, 0) AS posthistory_events,
  COALESCE(tc.tag_count_sum, 0) AS tag_count_sum,
  COALESCE(pl.outgoing_links, 0) AS outgoing_links
FROM users u
LEFT JOIN owner_posts op ON op.user_id = u.id
LEFT JOIN editor_posts ep ON ep.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN tag_counts tc ON tc.user_id = u.id
LEFT JOIN post_links pl ON pl.user_id = u.id
ORDER BY posts_owned DESC, total_post_score DESC
LIMIT 100
