WITH forum_activity AS (
   SELECT
      f.id AS forum_id,
      f.title AS forum_title,
      f.moderator_person_id,
      mod.first_name AS moderator_first_name,
      mod.last_name AS moderator_last_name,
      COUNT(DISTINCT p.id) AS total_posts,
      COUNT(DISTINCT c.id) AS total_comments,
      AVG(c.length) AS avg_comment_length,
      COUNT(DISTINCT cht.tag_id) AS distinct_comment_tags,
      COUNT(DISTINCT pht.tag_id) AS distinct_post_tags,
      COUNT(DISTINCT fm.person_id) AS total_members
   FROM forum f
   LEFT JOIN person mod ON f.moderator_person_id = mod.id
   LEFT JOIN post p ON p.container_forum_id = f.id
   LEFT JOIN comment c ON c.parent_post_id = p.id
   LEFT JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
   LEFT JOIN post_has_tag_tag pht ON pht.post_id = p.id
   LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
   GROUP BY f.id, f.title, f.moderator_person_id, mod.first_name, mod.last_name
)
SELECT
   forum_id,
   forum_title,
   moderator_first_name,
   moderator_last_name,
   total_posts,
   total_comments,
   avg_comment_length,
   distinct_comment_tags,
   distinct_post_tags,
   total_members
FROM forum_activity
ORDER BY total_posts DESC, total_comments DESC
LIMIT 10
