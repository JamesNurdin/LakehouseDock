WITH comment_likes AS (
    SELECT c.id AS comment_id,
           c.creation_date,
           c.creator_person_id,
           c.location_country_id,
           c.browser_used,
           c.length,
           c.parent_comment_id,
           COUNT(pl.person_id) AS like_count
    FROM comment c
    LEFT JOIN person_likes_comment pl
      ON pl.comment_id = c.id
    GROUP BY c.id,
             c.creation_date,
             c.creator_person_id,
             c.location_country_id,
             c.browser_used,
             c.length,
             c.parent_comment_id
),

child_like_agg AS (
    SELECT cl.parent_comment_id AS parent_comment_id,
           SUM(cl.like_count) AS child_like_sum,
           COUNT(cl.comment_id) AS child_comment_cnt
    FROM comment_likes cl
    WHERE cl.parent_comment_id IS NOT NULL
    GROUP BY cl.parent_comment_id
)

SELECT p.comment_id,
       p.like_count AS own_like_count,
       COALESCE(ca.child_like_sum, 0) AS child_like_sum,
       p.like_count + COALESCE(ca.child_like_sum, 0) AS total_like_sum,
       p.length,
       p.browser_used,
       p.location_country_id,
       CASE WHEN p.like_count > 0
            THEN CAST(COALESCE(ca.child_like_sum, 0) AS double) / p.like_count
            ELSE NULL
       END AS child_to_own_ratio,
       p.creation_date
FROM comment_likes p
LEFT JOIN child_like_agg ca
  ON p.comment_id = ca.parent_comment_id
ORDER BY total_like_sum DESC
LIMIT 10
