WITH
  person_posts AS (
    SELECT
      p.id AS person_id,
      COUNT(DISTINCT po.id) AS posts_created,
      SUM(COALESCE(po.length, 0)) AS total_post_length,
      COUNT(DISTINCT pt.tag_id) AS distinct_post_tags
    FROM person p
    LEFT JOIN post po ON po.creator_person_id = p.id
    LEFT JOIN post_has_tag_tag pt ON pt.post_id = po.id
    GROUP BY p.id
  ),
  person_comments AS (
    SELECT
      p.id AS person_id,
      COUNT(DISTINCT c.id) AS comments_created,
      SUM(COALESCE(c.length, 0)) AS total_comment_length,
      COUNT(DISTINCT ct.tag_id) AS distinct_comment_tags
    FROM person p
    LEFT JOIN comment c ON c.creator_person_id = p.id
    LEFT JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    GROUP BY p.id
  ),
  person_likes_given AS (
    SELECT
      p.id AS person_id,
      COUNT(DISTINCT plp.post_id) AS likes_given_posts,
      COUNT(DISTINCT plc.comment_id) AS likes_given_comments
    FROM person p
    LEFT JOIN person_likes_post plp ON plp.person_id = p.id
    LEFT JOIN person_likes_comment plc ON plc.person_id = p.id
    GROUP BY p.id
  ),
  person_likes_received AS (
    SELECT
      p.id AS person_id,
      COUNT(DISTINCT plp.person_id) AS likes_received_posts,
      COUNT(DISTINCT plc.person_id) AS likes_received_comments
    FROM person p
    LEFT JOIN post po ON po.creator_person_id = p.id
    LEFT JOIN person_likes_post plp ON plp.post_id = po.id
    LEFT JOIN comment c ON c.creator_person_id = p.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY p.id
  ),
  person_interests AS (
    SELECT
      p.id AS person_id,
      COUNT(DISTINCT pit.tag_id) AS distinct_interests
    FROM person p
    LEFT JOIN person_has_interest_tag pit ON pit.person_id = p.id
    GROUP BY p.id
  )
SELECT
  p.id AS person_id,
  p.first_name,
  p.last_name,
  COALESCE(pp.posts_created, 0) AS posts_created,
  COALESCE(pc.comments_created, 0) AS comments_created,
  COALESCE(plg.likes_given_posts, 0) AS likes_given_posts,
  COALESCE(plg.likes_given_comments, 0) AS likes_given_comments,
  COALESCE(plr.likes_received_posts, 0) AS likes_received_posts,
  COALESCE(plr.likes_received_comments, 0) AS likes_received_comments,
  COALESCE(pi.distinct_interests, 0) AS distinct_interests,
  COALESCE(pp.distinct_post_tags, 0) AS distinct_post_tags,
  COALESCE(pc.distinct_comment_tags, 0) AS distinct_comment_tags,
  COALESCE(pp.total_post_length, 0) AS total_post_length,
  COALESCE(pc.total_comment_length, 0) AS total_comment_length
FROM person p
LEFT JOIN person_posts pp ON pp.person_id = p.id
LEFT JOIN person_comments pc ON pc.person_id = p.id
LEFT JOIN person_likes_given plg ON plg.person_id = p.id
LEFT JOIN person_likes_received plr ON plr.person_id = p.id
LEFT JOIN person_interests pi ON pi.person_id = p.id
ORDER BY p.id
