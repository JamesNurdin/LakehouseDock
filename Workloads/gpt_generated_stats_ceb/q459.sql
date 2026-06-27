WITH post_stats AS (
  SELECT
    p.owneruserid,
    COUNT(*) AS post_count,
    COALESCE(SUM(p.score), 0) AS total_post_score
  FROM posts p
  GROUP BY p.owneruserid
),
comment_stats AS (
  SELECT
    c.userid,
    COUNT(*) AS comment_count
  FROM comments c
  GROUP BY c.userid
),
vote_stats AS (
  SELECT
    v.userid,
    COUNT(*) AS vote_count
  FROM votes v
  GROUP BY v.userid
),
badge_stats AS (
  SELECT
    b.userid,
    COUNT(*) AS badge_count
  FROM badges b
  GROUP BY b.userid
),
edit_stats AS (
  SELECT
    ph.userid,
    COUNT(*) AS edit_count
  FROM posthistory ph
  GROUP BY ph.userid
),
tag_stats AS (
  SELECT
    p.owneruserid,
    COUNT(*) AS tag_count
  FROM tags t
  JOIN posts p ON t.excerptpostid = p.id
  GROUP BY p.owneruserid
),
link_stats AS (
  SELECT
    p.owneruserid,
    COUNT(*) AS link_count
  FROM postlinks pl
  JOIN posts p ON pl.postid = p.id
  GROUP BY p.owneruserid
)
SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(ps.post_count, 0) AS post_count,
  COALESCE(ps.total_post_score, 0) AS total_post_score,
  CASE WHEN COALESCE(ps.post_count, 0) > 0 THEN ps.total_post_score / ps.post_count ELSE NULL END AS avg_post_score,
  COALESCE(cs.comment_count, 0) AS comment_count,
  COALESCE(vs.vote_count, 0) AS vote_count,
  COALESCE(bs.badge_count, 0) AS badge_count,
  COALESCE(es.edit_count, 0) AS edit_count,
  COALESCE(ts.tag_count, 0) AS tag_count,
  COALESCE(ls.link_count, 0) AS link_count,
  (COALESCE(ps.post_count, 0) + COALESCE(cs.comment_count, 0) + COALESCE(vs.vote_count, 0) + COALESCE(bs.badge_count, 0) + COALESCE(es.edit_count, 0) + COALESCE(ts.tag_count, 0) + COALESCE(ls.link_count, 0)) AS activity_score
FROM users u
LEFT JOIN post_stats ps ON ps.owneruserid = u.id
LEFT JOIN comment_stats cs ON cs.userid = u.id
LEFT JOIN vote_stats vs ON vs.userid = u.id
LEFT JOIN badge_stats bs ON bs.userid = u.id
LEFT JOIN edit_stats es ON es.userid = u.id
LEFT JOIN tag_stats ts ON ts.owneruserid = u.id
LEFT JOIN link_stats ls ON ls.owneruserid = u.id
ORDER BY activity_score DESC
LIMIT 10
