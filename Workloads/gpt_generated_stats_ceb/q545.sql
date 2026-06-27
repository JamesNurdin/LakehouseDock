WITH
  -- Badge count per user
  badge_counts AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
  ),
  -- Post aggregates per user (owner)
  post_agg AS (
    SELECT owneruserid,
           COUNT(*)                         AS post_count,
           SUM(score)                       AS total_post_score,
           SUM(answercount)                 AS total_answer_count,
           AVG(viewcount)                   AS avg_view_count,
           SUM(favoritecount)               AS total_favorite_count
    FROM posts
    GROUP BY owneruserid
  ),
  -- Comment activity on a user's posts (receiver)
  comment_on_posts_agg AS (
    SELECT p.owneruserid AS userid,
           COUNT(c.id)                     AS comment_on_user_posts_count,
           AVG(c.score)                    AS avg_comment_score_on_user_posts
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
  ),
  -- Comment activity made by a user (author)
  comment_by_user_agg AS (
    SELECT userid,
           COUNT(*)                        AS comment_made_count,
           AVG(score)                      AS avg_comment_score_by_user
    FROM comments
    GROUP BY userid
  ),
  -- Votes cast by a user
  votes_cast_agg AS (
    SELECT userid,
           COUNT(*)                        AS votes_cast_count,
           SUM(COALESCE(bountyamount, 0))  AS total_bounty_given
    FROM votes
    GROUP BY userid
  ),
  -- Votes received on a user's posts (owner)
  votes_received_agg AS (
    SELECT p.owneruserid AS userid,
           COUNT(v.id)                     AS votes_received_count,
           SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
  ),
  -- Tag usage on a user's posts
  tag_agg AS (
    SELECT p.owneruserid AS userid,
           COUNT(t.id)                     AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
  ),
  -- Post history events per user
  posthistory_agg AS (
    SELECT userid,
           COUNT(*)                        AS posthistory_count
    FROM posthistory
    GROUP BY userid
  ),
  -- Post links associated with a user's posts
  postlink_agg AS (
    SELECT p.owneruserid AS userid,
           COUNT(pl.id)                    AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
  )
SELECT
  u.id                                 AS user_id,
  u.reputation,
  u.creationdate,
  u.views,
  u.upvotes,
  u.downvotes,
  COALESCE(bc.badge_count, 0)                 AS badge_count,
  COALESCE(pa.post_count, 0)                  AS post_count,
  COALESCE(pa.total_post_score, 0)            AS total_post_score,
  COALESCE(pa.total_answer_count, 0)          AS total_answer_count,
  COALESCE(pa.avg_view_count, 0)              AS avg_view_count,
  COALESCE(pa.total_favorite_count, 0)        AS total_favorite_count,
  COALESCE(cop.comment_on_user_posts_count, 0) AS comment_on_user_posts_count,
  COALESCE(cop.avg_comment_score_on_user_posts, 0) AS avg_comment_score_on_user_posts,
  COALESCE(cbu.comment_made_count, 0)          AS comment_made_count,
  COALESCE(cbu.avg_comment_score_by_user, 0)  AS avg_comment_score_by_user,
  COALESCE(vc.votes_cast_count, 0)            AS votes_cast_count,
  COALESCE(vc.total_bounty_given, 0)          AS total_bounty_given,
  COALESCE(vr.votes_received_count, 0)        AS votes_received_count,
  COALESCE(vr.total_bounty_received, 0)       AS total_bounty_received,
  COALESCE(tg.tag_count, 0)                   AS tag_count,
  COALESCE(ph.posthistory_count, 0)           AS posthistory_count,
  COALESCE(pl.postlink_count, 0)              AS postlink_count
FROM users u
LEFT JOIN badge_counts bc               ON bc.userid = u.id
LEFT JOIN post_agg pa                    ON pa.owneruserid = u.id
LEFT JOIN comment_on_posts_agg cop       ON cop.userid = u.id
LEFT JOIN comment_by_user_agg cbu        ON cbu.userid = u.id
LEFT JOIN votes_cast_agg vc              ON vc.userid = u.id
LEFT JOIN votes_received_agg vr          ON vr.userid = u.id
LEFT JOIN tag_agg tg                     ON tg.userid = u.id
LEFT JOIN posthistory_agg ph             ON ph.userid = u.id
LEFT JOIN postlink_agg pl                ON pl.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
