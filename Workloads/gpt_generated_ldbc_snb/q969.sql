WITH forum_posts AS (
   SELECT
     f.id AS forum_id,
     p.id AS post_id,
     p.length AS post_length,
     p.creator_person_id AS creator_person_id
   FROM forum f
   JOIN post p ON p.container_forum_id = f.id
),
forum_comments AS (
   SELECT
     f.id AS forum_id,
     c.id AS comment_id,
     c.length AS comment_length,
     c.creator_person_id AS creator_person_id
   FROM forum f
   JOIN post p ON p.container_forum_id = f.id
   JOIN comment c ON c.parent_post_id = p.id
),
forum_comment_tags AS (
   SELECT
     f.id AS forum_id,
     ct.tag_id AS tag_id
   FROM forum f
   JOIN post p ON p.container_forum_id = f.id
   JOIN comment c ON c.parent_post_id = p.id
   JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
),
forum_tags AS (
   SELECT
     forum_id,
     tag_id
   FROM forum_has_tag_tag
),
forum_participants AS (
   SELECT DISTINCT forum_id, creator_person_id AS person_id
   FROM (
      SELECT forum_id, creator_person_id FROM forum_posts
      UNION ALL
      SELECT forum_id, creator_person_id FROM forum_comments
   )
),
participant_interest_tags AS (
   SELECT DISTINCT fp.forum_id, pit.tag_id AS interest_tag_id
   FROM forum_participants fp
   JOIN person_has_interest_tag pit ON pit.person_id = fp.person_id
)
SELECT
   f.id AS forum_id,
   f.title AS forum_title,
   COUNT(DISTINCT fp.post_id) AS post_count,
   AVG(fp.post_length) AS avg_post_length,
   COUNT(DISTINCT fc.comment_id) AS comment_count,
   AVG(fc.comment_length) AS avg_comment_length,
   COUNT(DISTINCT fp2.person_id) AS participant_count,
   COUNT(DISTINCT ft.tag_id) AS forum_tag_count,
   COUNT(DISTINCT fct.tag_id) AS comment_tag_count,
   COUNT(DISTINCT pit.interest_tag_id) AS participant_interest_tag_count
FROM forum f
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN forum_tags ft ON ft.forum_id = f.id
LEFT JOIN forum_comment_tags fct ON fct.forum_id = f.id
LEFT JOIN forum_participants fp2 ON fp2.forum_id = f.id
LEFT JOIN participant_interest_tags pit ON pit.forum_id = f.id
GROUP BY f.id, f.title
ORDER BY post_count DESC
LIMIT 10
