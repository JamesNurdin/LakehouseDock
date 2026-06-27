WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title
    FROM forum f
),
post_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           COUNT(DISTINCT p.creator_person_id) AS distinct_post_creator_count
    FROM post p
    GROUP BY p.container_forum_id
),
comment_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           COUNT(DISTINCT c.creator_person_id) AS distinct_commenter_count
    FROM comment c
    JOIN post p
      ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_like_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT plp.person_id) AS post_like_user_count
    FROM person_likes_post plp
    JOIN post p
      ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_like_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT plc.person_id) AS comment_like_user_count
    FROM person_likes_comment plc
    JOIN comment c
      ON plc.comment_id = c.id
    JOIN post p
      ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
tag_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pht.tag_id) AS distinct_tag_count
    FROM post_has_tag_tag pht
    JOIN post p
      ON pht.post_id = p.id
    GROUP BY p.container_forum_id
),
interest_tag_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pit.tag_id) AS distinct_interest_tag_of_likers
    FROM person_likes_post plp
    JOIN post p
      ON plp.post_id = p.id
    JOIN person per
      ON plp.person_id = per.id
    JOIN person_has_interest_tag pit
      ON pit.person_id = per.id
    GROUP BY p.container_forum_id
)
SELECT fb.forum_id,
       fb.forum_title,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(pl.post_like_user_count, 0) AS post_like_user_count,
       COALESCE(cl.comment_like_user_count, 0) AS comment_like_user_count,
       COALESCE(t.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(p.distinct_post_creator_count, 0) AS distinct_post_creator_count,
       COALESCE(c.distinct_commenter_count, 0) AS distinct_commenter_count,
       COALESCE(it.distinct_interest_tag_of_likers, 0) AS distinct_interest_tag_of_likers,
       -- derived metrics
       (COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0)) AS total_content,
       (COALESCE(pl.post_like_user_count, 0) + COALESCE(cl.comment_like_user_count, 0)) AS total_likes,
       (COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0)
        + COALESCE(pl.post_like_user_count, 0) + COALESCE(cl.comment_like_user_count, 0)) AS engagement_score
FROM forum_base fb
LEFT JOIN post_agg p
  ON p.forum_id = fb.forum_id
LEFT JOIN comment_agg c
  ON c.forum_id = fb.forum_id
LEFT JOIN post_like_agg pl
  ON pl.forum_id = fb.forum_id
LEFT JOIN comment_like_agg cl
  ON cl.forum_id = fb.forum_id
LEFT JOIN tag_agg t
  ON t.forum_id = fb.forum_id
LEFT JOIN interest_tag_agg it
  ON it.forum_id = fb.forum_id
ORDER BY engagement_score DESC
LIMIT 10
