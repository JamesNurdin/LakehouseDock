WITH tag_analytics AS (
  SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    COUNT(DISTINCT p.id) AS post_count,
    COUNT(DISTINCT p.creator_person_id) AS post_author_count,
    COUNT(DISTINCT f.id) AS forum_count,
    COUNT(DISTINCT mod_person.id) AS forum_moderator_count,
    COUNT(DISTINCT c.id) AS comment_count,
    COUNT(DISTINCT c.creator_person_id) AS comment_author_count,
    COUNT(DISTINCT plp.person_id) AS post_like_user_count,
    COUNT(DISTINCT plc.person_id) AS comment_like_user_count,
    COUNT(DISTINCT phi.person_id) AS interest_user_count
  FROM tag t
  LEFT JOIN post_has_tag_tag pht
    ON pht.tag_id = t.id
  LEFT JOIN post p
    ON p.id = pht.post_id
  LEFT JOIN person post_author
    ON post_author.id = p.creator_person_id
  LEFT JOIN person_likes_post plp
    ON plp.post_id = p.id
  LEFT JOIN forum f
    ON f.id = p.container_forum_id
  LEFT JOIN person mod_person
    ON mod_person.id = f.moderator_person_id
  LEFT JOIN comment_has_tag_tag cht
    ON cht.tag_id = t.id
  LEFT JOIN comment c
    ON c.id = cht.comment_id
  LEFT JOIN person comment_author
    ON comment_author.id = c.creator_person_id
  LEFT JOIN person_likes_comment plc
    ON plc.comment_id = c.id
  LEFT JOIN person_has_interest_tag phi
    ON phi.tag_id = t.id
  GROUP BY t.id, t.name
)
SELECT
  tag_id,
  tag_name,
  post_count,
  post_author_count,
  forum_count,
  forum_moderator_count,
  comment_count,
  comment_author_count,
  post_like_user_count,
  comment_like_user_count,
  interest_user_count
FROM tag_analytics
ORDER BY post_count DESC, comment_count DESC
LIMIT 50
