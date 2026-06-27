WITH user_posts AS (
  SELECT
    p.owneruserid AS user_id,
    COUNT(*) AS owned_posts,
    COALESCE(SUM(p.score), 0) AS owned_posts_score,
    COALESCE(SUM(p.viewcount), 0) AS owned_posts_viewcount,
    COALESCE(SUM(p.answercount), 0) AS owned_posts_answercount,
    COALESCE(SUM(p.commentcount), 0) AS owned_posts_commentcount,
    COALESCE(SUM(p.favoritecount), 0) AS owned_posts_favoritecount
  FROM posts p
  GROUP BY p.owneruserid
),
user_comments AS (
  SELECT
    c.userid AS user_id,
    COUNT(*) AS comments_made,
    COALESCE(SUM(c.score), 0) AS comments_score
  FROM comments c
  GROUP BY c.userid
),
user_votes_cast AS (
  SELECT
    v.userid AS user_id,
    COUNT(*) AS votes_cast
  FROM votes v
  GROUP BY v.userid
),
user_post_edits AS (
  SELECT
    ph.userid AS user_id,
    COUNT(*) AS post_edits
  FROM posthistory ph
  GROUP BY ph.userid
),
user_badges AS (
  SELECT
    b.userid AS user_id,
    COUNT(*) AS badges_earned
  FROM badges b
  GROUP BY b.userid
),
votes_received AS (
  SELECT
    p.owneruserid AS user_id,
    COUNT(v.id) AS votes_received_on_owned_posts
  FROM posts p
  JOIN votes v ON v.postid = p.id
  GROUP BY p.owneruserid
),
post_links_outbound AS (
  SELECT
    p.owneruserid AS user_id,
    COUNT(pl.id) AS outbound_links
  FROM posts p
  JOIN postlinks pl ON pl.postid = p.id
  GROUP BY p.owneruserid
),
post_links_inbound AS (
  SELECT
    p.owneruserid AS user_id,
    COUNT(pl.id) AS inbound_links
  FROM posts p
  JOIN postlinks pl ON pl.relatedpostid = p.id
  GROUP BY p.owneruserid
),
user_tags AS (
  SELECT
    p.owneruserid AS user_id,
    COUNT(DISTINCT t.id) AS distinct_tags
  FROM posts p
  JOIN tags t ON t.excerptpostid = p.id
  GROUP BY p.owneruserid
)
SELECT
  u.id AS user_id,
  u.reputation,
  u.creationdate,
  u.views,
  u.upvotes,
  u.downvotes,
  COALESCE(up.owned_posts, 0) AS owned_posts,
  COALESCE(up.owned_posts_score, 0) AS owned_posts_score,
  COALESCE(up.owned_posts_viewcount, 0) AS owned_posts_viewcount,
  COALESCE(up.owned_posts_answercount, 0) AS owned_posts_answercount,
  COALESCE(up.owned_posts_commentcount, 0) AS owned_posts_commentcount,
  COALESCE(up.owned_posts_favoritecount, 0) AS owned_posts_favoritecount,
  COALESCE(uc.comments_made, 0) AS comments_made,
  COALESCE(uc.comments_score, 0) AS comments_score,
  COALESCE(uvc.votes_cast, 0) AS votes_cast,
  COALESCE(vr.votes_received_on_owned_posts, 0) AS votes_received_on_owned_posts,
  COALESCE(uped.post_edits, 0) AS post_edits,
  COALESCE(ub.badges_earned, 0) AS badges_earned,
  COALESCE(pl_out.outbound_links, 0) AS outbound_links,
  COALESCE(pl_in.inbound_links, 0) AS inbound_links,
  COALESCE(ut.distinct_tags, 0) AS distinct_tags
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN votes_received vr ON vr.user_id = u.id
LEFT JOIN user_post_edits uped ON uped.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN post_links_outbound pl_out ON pl_out.user_id = u.id
LEFT JOIN post_links_inbound pl_in ON pl_in.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
