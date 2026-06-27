WITH forum_posts AS (
    SELECT f.id    AS forum_id,
           f.title AS forum_title,
           COUNT(DISTINCT p.id) AS post_count
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
interest_comment_likes AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT ROW(plc.person_id, plc.comment_id)) AS like_count
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    JOIN comment c
      ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag ctt
      ON ctt.comment_id = c.id
    JOIN tag t
      ON t.id = ctt.tag_id
    JOIN forum_has_member_person fmp
      ON fmp.forum_id = f.id
    JOIN person_has_interest_tag pht
      ON pht.person_id = fmp.person_id
     AND pht.tag_id = t.id
    JOIN person_likes_comment plc
      ON plc.comment_id = c.id
    GROUP BY f.id
)
SELECT fp.forum_id,
       fp.forum_title,
       fp.post_count,
       COALESCE(icl.like_count, 0) AS like_count,
       CASE WHEN fp.post_count > 0
            THEN CAST(COALESCE(icl.like_count, 0) AS DOUBLE) / fp.post_count
            ELSE 0
       END AS likes_per_post
FROM forum_posts fp
LEFT JOIN interest_comment_likes icl
  ON icl.forum_id = fp.forum_id
ORDER BY likes_per_post DESC
LIMIT 10
