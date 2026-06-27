WITH tag_posts AS (
  SELECT
    t.id AS tag_id,
    p.id AS post_id,
    p.owneruserid,
    p.lasteditoruserid,
    p.score AS post_score,
    p.viewcount,
    p.answercount,
    p.commentcount,
    p.favoritecount
  FROM tags t
  JOIN posts p ON t.excerptpostid = p.id
),

post_agg AS (
  SELECT
    tp.tag_id,
    COUNT(DISTINCT tp.post_id) AS post_count,
    SUM(tp.post_score) AS total_post_score,
    AVG(tp.post_score) AS avg_post_score,
    SUM(tp.viewcount) AS total_views,
    SUM(tp.answercount) AS total_answers,
    SUM(tp.commentcount) AS total_comments,
    SUM(tp.favoritecount) AS total_favorites,
    COUNT(DISTINCT tp.owneruserid) AS distinct_owners,
    COUNT(DISTINCT tp.lasteditoruserid) AS distinct_editors
  FROM tag_posts tp
  GROUP BY tp.tag_id
),

comment_agg AS (
  SELECT
    tp.tag_id,
    COUNT(DISTINCT c.userid) AS distinct_commenters,
    COUNT(*) AS total_comments_on_posts
  FROM tag_posts tp
  JOIN comments c ON c.postid = tp.post_id
  GROUP BY tp.tag_id
),

vote_agg AS (
  SELECT
    tp.tag_id,
    COUNT(DISTINCT v.userid) AS distinct_voters,
    COUNT(*) AS total_votes
  FROM tag_posts tp
  JOIN votes v ON v.postid = tp.post_id
  GROUP BY tp.tag_id
),

badge_agg AS (
  SELECT
    ub.tag_id,
    COUNT(DISTINCT ub.userid) AS distinct_badge_earners
  FROM (
    SELECT t.id AS tag_id, u.id AS userid
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    JOIN users u ON u.id = p.owneruserid
    JOIN badges b ON b.userid = u.id
    UNION
    SELECT t.id AS tag_id, u.id AS userid
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    JOIN users u ON u.id = p.lasteditoruserid
    JOIN badges b ON b.userid = u.id
  ) ub
  GROUP BY ub.tag_id
)

SELECT
  pa.tag_id,
  pa.post_count,
  pa.total_post_score,
  pa.avg_post_score,
  pa.total_views,
  pa.total_answers,
  pa.total_comments,
  pa.total_favorites,
  pa.distinct_owners,
  pa.distinct_editors,
  COALESCE(ca.distinct_commenters, 0) AS distinct_commenters,
  COALESCE(va.distinct_voters, 0) AS distinct_voters,
  COALESCE(ba.distinct_badge_earners, 0) AS distinct_badge_earners
FROM post_agg pa
LEFT JOIN comment_agg ca ON ca.tag_id = pa.tag_id
LEFT JOIN vote_agg va ON va.tag_id = pa.tag_id
LEFT JOIN badge_agg ba ON ba.tag_id = pa.tag_id
ORDER BY pa.total_post_score DESC
LIMIT 20
