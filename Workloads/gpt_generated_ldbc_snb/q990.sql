WITH forum_moderator AS (
    SELECT f.id AS forum_id,
           f.title,
           p.first_name AS moderator_first_name,
           p.last_name AS moderator_last_name
    FROM forum f
    JOIN person p
      ON f.moderator_person_id = p.id
),
forum_members AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
forum_posts AS (
    SELECT container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           SUM(length) AS total_post_length,
           AVG(length) AS avg_post_length
    FROM post
    GROUP BY container_forum_id
),
forum_comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p
      ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS like_count
    FROM person_likes_post plp
    JOIN post p
      ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_post_tags AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pht.tag_id) AS post_tag_count
    FROM post_has_tag_tag pht
    JOIN post p
      ON pht.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_tags AS (
    SELECT forum_id,
           COUNT(DISTINCT tag_id) AS forum_tag_count
    FROM forum_has_tag_tag
    GROUP BY forum_id
)
SELECT fm.forum_id,
       fm.title,
       fm.moderator_first_name,
       fm.moderator_last_name,
       COALESCE(m.member_count, 0) AS member_count,
       COALESCE(pst.post_count, 0) AS post_count,
       COALESCE(pst.total_post_length, 0) AS total_post_length,
       COALESCE(pst.avg_post_length, 0) AS avg_post_length,
       COALESCE(cmt.comment_count, 0) AS comment_count,
       COALESCE(cmt.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(l.like_count, 0) AS like_count,
       COALESCE(pt.post_tag_count, 0) AS post_tag_count,
       COALESCE(ft.forum_tag_count, 0) AS forum_tag_count
FROM forum_moderator fm
LEFT JOIN forum_members m
  ON fm.forum_id = m.forum_id
LEFT JOIN forum_posts pst
  ON fm.forum_id = pst.forum_id
LEFT JOIN forum_comments cmt
  ON fm.forum_id = cmt.forum_id
LEFT JOIN forum_likes l
  ON fm.forum_id = l.forum_id
LEFT JOIN forum_post_tags pt
  ON fm.forum_id = pt.forum_id
LEFT JOIN forum_tags ft
  ON fm.forum_id = ft.forum_id
ORDER BY fm.forum_id
