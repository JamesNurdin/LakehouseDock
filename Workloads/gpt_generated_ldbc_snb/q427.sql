WITH forum_info AS (
    SELECT f.id AS forum_id,
           f.title
    FROM forum f
),
moderator_info AS (
    SELECT f.id AS forum_id,
           p.first_name AS moderator_first_name,
           p.last_name  AS moderator_last_name
    FROM forum f
    JOIN person p
      ON f.moderator_person_id = p.id
),
posts_by_forum AS (
    SELECT p.id AS post_id,
           p.container_forum_id AS forum_id
    FROM post p
),
likes_with_forum AS (
    SELECT pl.person_id AS liker_id,
           pl.post_id,
           p.container_forum_id AS forum_id
    FROM person_likes_post pl
    JOIN post p
      ON pl.post_id = p.id
),
likes_with_details AS (
    SELECT l.forum_id,
           l.liker_id,
           ih.tag_id,
           wc.company_id
    FROM likes_with_forum l
    LEFT JOIN person_has_interest_tag ih
      ON ih.person_id = l.liker_id
    LEFT JOIN person_work_at_company wc
      ON wc.person_id = l.liker_id
),
post_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT post_id) AS total_posts
    FROM posts_by_forum
    GROUP BY forum_id
),
like_counts AS (
    SELECT forum_id,
           COUNT(*) AS total_likes,
           COUNT(DISTINCT liker_id) AS distinct_likers
    FROM likes_with_forum
    GROUP BY forum_id
),
detail_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT tag_id)    AS distinct_interest_tags,
           COUNT(DISTINCT company_id) AS distinct_companies
    FROM likes_with_details
    GROUP BY forum_id
)
SELECT
    fi.forum_id,
    fi.title,
    mi.moderator_first_name,
    mi.moderator_last_name,
    COALESCE(pc.total_posts, 0)           AS total_posts,
    COALESCE(lc.total_likes, 0)           AS total_likes,
    COALESCE(lc.distinct_likers, 0)      AS distinct_likers,
    COALESCE(dc.distinct_interest_tags, 0) AS distinct_interest_tags,
    COALESCE(dc.distinct_companies, 0)     AS distinct_companies
FROM forum_info fi
JOIN moderator_info mi
  ON mi.forum_id = fi.forum_id
LEFT JOIN post_counts pc
  ON pc.forum_id = fi.forum_id
LEFT JOIN like_counts lc
  ON lc.forum_id = fi.forum_id
LEFT JOIN detail_counts dc
  ON dc.forum_id = fi.forum_id
ORDER BY total_likes DESC
LIMIT 10
