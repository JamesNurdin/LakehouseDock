WITH forum_members AS (
  SELECT
    fhm.forum_id,
    COUNT(DISTINCT fhm.person_id) AS member_count,
    COUNT(DISTINCT pht.tag_id) AS distinct_interest_tag_count
  FROM forum_has_member_person fhm
  JOIN person p
    ON fhm.person_id = p.id
  LEFT JOIN person_has_interest_tag pht
    ON p.id = pht.person_id
  GROUP BY fhm.forum_id
),
forum_posts AS (
  SELECT
    p.container_forum_id AS forum_id,
    COUNT(DISTINCT p.id) AS post_count,
    AVG(p.length) AS avg_post_length,
    COALESCE(SUM(pl.like_cnt), 0) AS total_post_likes
  FROM post p
  LEFT JOIN (
    SELECT post_id, COUNT(*) AS like_cnt
    FROM person_likes_post
    GROUP BY post_id
  ) pl
    ON pl.post_id = p.id
  GROUP BY p.container_forum_id
),
forum_comments AS (
  SELECT
    p.container_forum_id AS forum_id,
    COUNT(DISTINCT c.id) AS comment_count,
    AVG(c.length) AS avg_comment_length,
    COALESCE(SUM(cl.like_cnt), 0) AS total_comment_likes
  FROM comment c
  JOIN post p
    ON c.parent_post_id = p.id
  LEFT JOIN (
    SELECT comment_id, COUNT(*) AS like_cnt
    FROM person_likes_comment
    GROUP BY comment_id
  ) cl
    ON cl.comment_id = c.id
  GROUP BY p.container_forum_id
),
forum_moderator AS (
  SELECT
    f.id AS forum_id,
    p.first_name AS moderator_first_name,
    p.last_name AS moderator_last_name
  FROM forum f
  JOIN person p
    ON f.moderator_person_id = p.id
)
SELECT
  f.id AS forum_id,
  f.title,
  fm.moderator_first_name,
  fm.moderator_last_name,
  COALESCE(mem.member_count, 0) AS member_count,
  COALESCE(mem.distinct_interest_tag_count, 0) AS distinct_interest_tag_count,
  COALESCE(pst.post_count, 0) AS post_count,
  pst.avg_post_length,
  pst.total_post_likes,
  COALESCE(cmt.comment_count, 0) AS comment_count,
  cmt.avg_comment_length,
  cmt.total_comment_likes
FROM forum f
LEFT JOIN forum_moderator fm
  ON f.id = fm.forum_id
LEFT JOIN forum_members mem
  ON f.id = mem.forum_id
LEFT JOIN forum_posts pst
  ON f.id = pst.forum_id
LEFT JOIN forum_comments cmt
  ON f.id = cmt.forum_id
ORDER BY member_count DESC, post_count DESC
LIMIT 100
