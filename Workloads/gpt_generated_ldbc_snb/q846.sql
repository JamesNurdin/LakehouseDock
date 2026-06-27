WITH forum_stats AS (
  SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    mod.first_name AS moderator_first_name,
    mod.last_name AS moderator_last_name,
    COUNT(DISTINCT p.id) AS post_count,
    COUNT(DISTINCT c.id) AS comment_count,
    AVG(p.length) AS avg_post_length,
    AVG(c.length) AS avg_comment_length,
    COUNT(DISTINCT pt.tag_id) AS distinct_post_tags,
    COUNT(DISTINCT ct.tag_id) AS distinct_comment_tags,
    COUNT(DISTINCT pl.id) AS member_count
  FROM forum f
  LEFT JOIN person mod ON f.moderator_person_id = mod.id
  LEFT JOIN post p ON p.container_forum_id = f.id
  LEFT JOIN comment c ON c.parent_post_id = p.id
  LEFT JOIN post_has_tag_tag pt ON pt.post_id = p.id
  LEFT JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
  LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
  LEFT JOIN person pl ON fm.person_id = pl.id
  GROUP BY f.id, f.title, mod.first_name, mod.last_name
),
forum_top_post_tag AS (
  SELECT
    f.id AS forum_id,
    t.id AS tag_id,
    t.name AS tag_name,
    COUNT(*) AS tag_usage,
    ROW_NUMBER() OVER (PARTITION BY f.id ORDER BY COUNT(*) DESC) AS tag_rank
  FROM forum f
  JOIN post p ON p.container_forum_id = f.id
  JOIN post_has_tag_tag pt ON pt.post_id = p.id
  JOIN tag t ON pt.tag_id = t.id
  GROUP BY f.id, t.id, t.name
)
SELECT
  fs.forum_id,
  fs.forum_title,
  fs.moderator_first_name,
  fs.moderator_last_name,
  fs.post_count,
  fs.comment_count,
  fs.avg_post_length,
  fs.avg_comment_length,
  fs.distinct_post_tags,
  fs.distinct_comment_tags,
  fs.member_count,
  RANK() OVER (ORDER BY fs.post_count DESC) AS forum_rank,
  ftpt.tag_name AS top_post_tag,
  ftpt.tag_usage AS top_post_tag_usage
FROM forum_stats fs
LEFT JOIN forum_top_post_tag ftpt
  ON ftpt.forum_id = fs.forum_id AND ftpt.tag_rank = 1
ORDER BY fs.post_count DESC
LIMIT 10
