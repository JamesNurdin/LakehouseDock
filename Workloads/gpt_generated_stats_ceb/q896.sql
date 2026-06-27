WITH
  -- Basic user information
  user_info AS (
    SELECT
      id,
      reputation,
      creationdate,
      views,
      upvotes,
      downvotes
    FROM users
  ),

  -- Aggregated post metrics per owner
  posts_agg AS (
    SELECT
      owneruserid,
      COUNT(*) AS post_count,
      SUM(score) AS total_post_score,
      AVG(score) AS avg_post_score,
      SUM(answercount) AS total_answer_count,
      SUM(commentcount) AS total_post_comment_count,
      SUM(favoritecount) AS total_favorite_count,
      SUM(viewcount) AS total_view_count
    FROM posts
    GROUP BY owneruserid
  ),

  -- Comments made by each user
  comments_made_agg AS (
    SELECT
      userid,
      COUNT(*) AS comments_made
    FROM comments
    GROUP BY userid
  ),

  -- Comments received on posts owned by each user
  comments_received_agg AS (
    SELECT
      posts.owneruserid AS owneruserid,
      COUNT(*) AS comments_received
    FROM comments
    JOIN posts ON comments.postid = posts.id
    GROUP BY posts.owneruserid
  ),

  -- Votes cast by each user (including breakdown by type)
  votes_cast_agg AS (
    SELECT
      userid,
      COUNT(*) AS votes_cast,
      SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes_cast,
      SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes_cast
    FROM votes
    GROUP BY userid
  ),

  -- Votes received on posts owned by each user (including breakdown by type)
  votes_received_agg AS (
    SELECT
      posts.owneruserid AS owneruserid,
      COUNT(*) AS votes_received,
      SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes_received,
      SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes_received
    FROM votes
    JOIN posts ON votes.postid = posts.id
    GROUP BY posts.owneruserid
  ),

  -- Badge count per user
  badges_agg AS (
    SELECT
      userid,
      COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
  ),

  -- Post‑history entries made by each user
  posthistory_agg AS (
    SELECT
      userid,
      COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
  ),

  -- Distinct tag excerpts attached to posts owned by each user
  tags_agg AS (
    SELECT
      posts.owneruserid AS owneruserid,
      COUNT(DISTINCT tags.id) AS tag_excerpt_count
    FROM tags
    JOIN posts ON tags.excerptpostid = posts.id
    GROUP BY posts.owneruserid
  ),

  -- Post‑link count for posts owned by each user
  postlinks_agg AS (
    SELECT
      posts.owneruserid AS owneruserid,
      COUNT(*) AS postlinks_count
    FROM postlinks
    JOIN posts ON postlinks.postid = posts.id
    GROUP BY posts.owneruserid
  )
SELECT
  user_info.id AS user_id,
  user_info.reputation,
  user_info.creationdate,
  user_info.views,
  user_info.upvotes,
  user_info.downvotes,
  COALESCE(posts_agg.post_count, 0) AS post_count,
  COALESCE(posts_agg.total_post_score, 0) AS total_post_score,
  COALESCE(posts_agg.avg_post_score, 0) AS avg_post_score,
  COALESCE(posts_agg.total_answer_count, 0) AS total_answer_count,
  COALESCE(posts_agg.total_post_comment_count, 0) AS total_post_comment_count,
  COALESCE(posts_agg.total_favorite_count, 0) AS total_favorite_count,
  COALESCE(posts_agg.total_view_count, 0) AS total_view_count,
  COALESCE(comments_made_agg.comments_made, 0) AS comments_made,
  COALESCE(comments_received_agg.comments_received, 0) AS comments_received,
  COALESCE(votes_cast_agg.votes_cast, 0) AS votes_cast,
  COALESCE(votes_cast_agg.up_votes_cast, 0) AS up_votes_cast,
  COALESCE(votes_cast_agg.down_votes_cast, 0) AS down_votes_cast,
  COALESCE(votes_received_agg.votes_received, 0) AS votes_received,
  COALESCE(votes_received_agg.up_votes_received, 0) AS up_votes_received,
  COALESCE(votes_received_agg.down_votes_received, 0) AS down_votes_received,
  COALESCE(badges_agg.badge_count, 0) AS badge_count,
  COALESCE(posthistory_agg.posthistory_count, 0) AS posthistory_count,
  COALESCE(tags_agg.tag_excerpt_count, 0) AS tag_excerpt_count,
  COALESCE(postlinks_agg.postlinks_count, 0) AS postlinks_count
FROM user_info
LEFT JOIN posts_agg ON posts_agg.owneruserid = user_info.id
LEFT JOIN comments_made_agg ON comments_made_agg.userid = user_info.id
LEFT JOIN comments_received_agg ON comments_received_agg.owneruserid = user_info.id
LEFT JOIN votes_cast_agg ON votes_cast_agg.userid = user_info.id
LEFT JOIN votes_received_agg ON votes_received_agg.owneruserid = user_info.id
LEFT JOIN badges_agg ON badges_agg.userid = user_info.id
LEFT JOIN posthistory_agg ON posthistory_agg.userid = user_info.id
LEFT JOIN tags_agg ON tags_agg.owneruserid = user_info.id
LEFT JOIN postlinks_agg ON postlinks_agg.owneruserid = user_info.id
ORDER BY total_post_score DESC
LIMIT 100
