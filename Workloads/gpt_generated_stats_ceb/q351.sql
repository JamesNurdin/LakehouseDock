WITH
  /* Posts owned by each user and their aggregate metrics */
  owned_posts AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS total_posts,
      SUM(p.score) AS total_score,
      SUM(p.viewcount) AS total_views,
      SUM(p.answercount) AS total_answers,
      SUM(p.commentcount) AS total_comments
    FROM posts p
    GROUP BY p.owneruserid
  ),

  /* Votes received on a user’s posts */
  votes_received AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(v.id) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id               -- votes.postid = posts.id
    GROUP BY p.owneruserid
  ),

  /* Votes cast by each user */
  votes_cast AS (
    SELECT
      v.userid AS user_id,
      COUNT(*) AS votes_cast
    FROM votes v
    GROUP BY v.userid
  ),

  /* Post‑history entries performed by each user */
  post_history AS (
    SELECT
      ph.userid AS user_id,
      COUNT(*) AS post_history_entries
    FROM posthistory ph
    GROUP BY ph.userid
  ),

  /* Posts where the user is the last editor */
  last_edits AS (
    SELECT
      p.lasteditoruserid AS user_id,
      COUNT(*) AS last_edit_posts
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
  ),

  /* Tag usage on a user’s posts */
  post_tags AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(t.id) AS tag_count,
      SUM(t.count) AS tag_total_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id        -- tags.excerptpostid = posts.id
    GROUP BY p.owneruserid
  ),

  /* Links originating from a user’s posts */
  post_links AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(pl.id) AS post_link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id               -- postlinks.postid = posts.id
    GROUP BY p.owneruserid
  ),

  /* Post‑history entries where the posthistorytypeid refers to a post owned by the user */
  posthistory_type AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(ph.id) AS posthistory_type_entries
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id    -- posthistory.posthistorytypeid = posts.id
    GROUP BY p.owneruserid
  )

SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(op.total_posts, 0)               AS total_posts,
  COALESCE(op.total_score, 0)               AS total_score,
  COALESCE(op.total_views, 0)               AS total_views,
  COALESCE(op.total_answers, 0)             AS total_answers,
  COALESCE(op.total_comments, 0)            AS total_comments,
  COALESCE(vr.votes_received, 0)            AS votes_received,
  COALESCE(vc.votes_cast, 0)                AS votes_cast,
  COALESCE(ph.post_history_entries, 0)      AS post_history_entries,
  COALESCE(le.last_edit_posts, 0)           AS last_edit_posts,
  COALESCE(pt.tag_count, 0)                 AS tag_count,
  COALESCE(pt.tag_total_count, 0)           AS tag_total_count,
  COALESCE(pl.post_link_count, 0)           AS post_link_count,
  COALESCE(pht.posthistory_type_entries,0)  AS posthistory_type_entries,
  CAST(COALESCE(op.total_score, 0) AS double) / NULLIF(COALESCE(op.total_posts, 0), 0) AS avg_score_per_post
FROM users u
LEFT JOIN owned_posts op      ON u.id = op.user_id          -- posts.owneruserid = users.id
LEFT JOIN votes_received vr   ON u.id = vr.user_id
LEFT JOIN votes_cast vc       ON u.id = vc.user_id
LEFT JOIN post_history ph     ON u.id = ph.user_id
LEFT JOIN last_edits le       ON u.id = le.user_id
LEFT JOIN post_tags pt        ON u.id = pt.user_id
LEFT JOIN post_links pl       ON u.id = pl.user_id
LEFT JOIN posthistory_type pht ON u.id = pht.user_id
ORDER BY avg_score_per_post DESC
LIMIT 10
