WITH forum_members AS (
  SELECT forum_has_member_person.forum_id AS forum_id,
         COUNT(DISTINCT forum_has_member_person.person_id) AS member_count
  FROM forum_has_member_person
  GROUP BY forum_has_member_person.forum_id
),
forum_posts AS (
  SELECT post.container_forum_id AS forum_id,
         COUNT(*) AS post_count,
         AVG(post.length) AS avg_post_length
  FROM post
  GROUP BY post.container_forum_id
),
forum_comments AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(*) AS comment_count,
         AVG(c.length) AS avg_comment_length
  FROM comment c
  JOIN post p ON c.parent_post_id = p.id
  GROUP BY p.container_forum_id
),
forum_likes AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(*) AS like_count
  FROM person_likes_post plp
  JOIN post p ON plp.post_id = p.id
  GROUP BY p.container_forum_id
),
forum_like_members AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(DISTINCT plp.person_id) AS distinct_like_member_count
  FROM person_likes_post plp
  JOIN post p ON plp.post_id = p.id
  GROUP BY p.container_forum_id
),
forum_post_tags AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(DISTINCT post_has_tag_tag.tag_id) AS distinct_post_tag_count
  FROM post_has_tag_tag
  JOIN post p ON post_has_tag_tag.post_id = p.id
  GROUP BY p.container_forum_id
),
forum_forum_tags AS (
  SELECT forum_has_tag_tag.forum_id AS forum_id,
         COUNT(DISTINCT forum_has_tag_tag.tag_id) AS distinct_forum_tag_count
  FROM forum_has_tag_tag
  GROUP BY forum_has_tag_tag.forum_id
),
moderators AS (
  SELECT person.id AS person_id,
         person.first_name,
         person.last_name
  FROM person
)
SELECT f.id AS forum_id,
       f.title,
       f.creation_date,
       mod.first_name AS moderator_first_name,
       mod.last_name AS moderator_last_name,
       COALESCE(fm.member_count, 0) AS member_count,
       COALESCE(fp.post_count, 0) AS post_count,
       fp.avg_post_length,
       COALESCE(fc.comment_count, 0) AS comment_count,
       fc.avg_comment_length,
       COALESCE(fl.like_count, 0) AS like_count,
       COALESCE(flm.distinct_like_member_count, 0) AS distinct_like_member_count,
       COALESCE(fpt.distinct_post_tag_count, 0) AS distinct_post_tag_count,
       COALESCE(fft.distinct_forum_tag_count, 0) AS distinct_forum_tag_count
FROM forum f
LEFT JOIN moderators mod ON f.moderator_person_id = mod.person_id
LEFT JOIN forum_members fm ON f.id = fm.forum_id
LEFT JOIN forum_posts fp ON f.id = fp.forum_id
LEFT JOIN forum_comments fc ON f.id = fc.forum_id
LEFT JOIN forum_likes fl ON f.id = fl.forum_id
LEFT JOIN forum_like_members flm ON f.id = flm.forum_id
LEFT JOIN forum_post_tags fpt ON f.id = fpt.forum_id
LEFT JOIN forum_forum_tags fft ON f.id = fft.forum_id
ORDER BY f.id
