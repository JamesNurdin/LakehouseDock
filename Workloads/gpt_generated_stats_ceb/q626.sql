WITH
  -- Posts created by each user
  user_posts AS (
    SELECT
      owneruserid AS user_id,
      COUNT(*) AS post_count,
      SUM(score) AS total_post_score,
      SUM(viewcount) AS total_views,
      AVG(CAST(answercount AS double)) AS avg_answer_count,
      AVG(CAST(commentcount AS double)) AS avg_comment_count,
      SUM(favoritecount) AS total_favorites
    FROM posts
    GROUP BY owneruserid
  ),
  -- Comments made by each user
  user_comments AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS comment_count,
      SUM(score) AS total_comment_score,
      AVG(CAST(score AS double)) AS avg_comment_score
    FROM comments
    GROUP BY userid
  ),
  -- Votes cast by each user
  user_votes AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS vote_count,
      SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_given,
      SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_given,
      SUM(COALESCE(bountyamount, 0)) AS total_bounty_given
    FROM votes
    GROUP BY userid
  ),
  -- Badges earned by each user
  user_badges AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
  ),
  -- Edits performed by each user (as last editor of a post)
  user_edits AS (
    SELECT
      lasteditoruserid AS user_id,
      COUNT(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
  ),
  -- Tags that appear on a user’s posts (via excerptpostid)
  user_tags AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
  ),
  -- Post‑history events performed by each user
  user_history AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS history_event_count
    FROM posthistory
    GROUP BY userid
  ),
  -- Outgoing post links created by a user’s posts
  user_postlinks_out AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS outgoing_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
  ),
  -- Incoming post links that point to a user’s posts
  user_postlinks_in AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS incoming_links
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
  )
SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(up.post_count, 0)               AS post_count,
  COALESCE(up.total_post_score, 0)        AS total_post_score,
  COALESCE(up.total_views, 0)             AS total_views,
  COALESCE(up.avg_answer_count, 0)        AS avg_answer_count,
  COALESCE(up.avg_comment_count, 0)       AS avg_comment_count,
  COALESCE(up.total_favorites, 0)         AS total_favorites,
  COALESCE(uc.comment_count, 0)           AS comment_count,
  COALESCE(uc.total_comment_score, 0)     AS total_comment_score,
  COALESCE(uc.avg_comment_score, 0)       AS avg_comment_score,
  COALESCE(uv.vote_count, 0)              AS vote_count,
  COALESCE(uv.upvotes_given, 0)           AS upvotes_given,
  COALESCE(uv.downvotes_given, 0)         AS downvotes_given,
  COALESCE(uv.total_bounty_given, 0)      AS total_bounty_given,
  COALESCE(ub.badge_count, 0)             AS badge_count,
  COALESCE(ue.edit_count, 0)              AS edit_count,
  COALESCE(ut.tag_count, 0)               AS tag_count,
  COALESCE(uh.history_event_count, 0)    AS history_event_count,
  COALESCE(upo.outgoing_links, 0)         AS outgoing_links,
  COALESCE(upi.incoming_links, 0)         AS incoming_links
FROM users u
LEFT JOIN user_posts up               ON up.user_id = u.id
LEFT JOIN user_comments uc            ON uc.user_id = u.id
LEFT JOIN user_votes uv               ON uv.user_id = u.id
LEFT JOIN user_badges ub              ON ub.user_id = u.id
LEFT JOIN user_edits ue               ON ue.user_id = u.id
LEFT JOIN user_tags ut                ON ut.user_id = u.id
LEFT JOIN user_history uh            ON uh.user_id = u.id
LEFT JOIN user_postlinks_out upo      ON upo.user_id = u.id
LEFT JOIN user_postlinks_in upi       ON upi.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
