/*
  Analytical query: Top 10 forums whose moderator lives in the city 'New York',
  ranked by total number of likes on posts and comments.  For each forum we
  report moderator name, member count, post/comment counts, total likes,
  distinct tags used (on posts and comments), and content length statistics.
*/
WITH forum_member_counts AS (
    SELECT
        fhm.forum_id,
        COUNT(DISTINCT fhm.person_id) AS member_count
    FROM forum_has_member_person fhm
    GROUP BY fhm.forum_id
),
forum_post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id)                AS post_count,
        SUM(p.length)                       AS total_post_length,
        COUNT(pl.person_id)                 AS post_like_count
    FROM post p
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id)                AS comment_count,
        SUM(c.length)                       AS total_comment_length,
        COUNT(cl.person_id)                 AS comment_like_count
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY p.container_forum_id
),
forum_tag_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT tag_id) AS distinct_tag_count
    FROM (
        -- Tags coming from posts
        SELECT
            p.container_forum_id AS forum_id,
            pht.tag_id           AS tag_id
        FROM post p
        JOIN post_has_tag_tag pht ON pht.post_id = p.id
        UNION ALL
        -- Tags coming from comments
        SELECT
            p.container_forum_id AS forum_id,
            cht.tag_id           AS tag_id
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    ) t
    GROUP BY forum_id
),
forum_moderator_info AS (
    SELECT
        f.id                     AS forum_id,
        f.title                  AS forum_title,
        f.moderator_person_id,
        p.first_name,
        p.last_name,
        pl.name                  AS moderator_city_name
    FROM forum f
    JOIN person p ON f.moderator_person_id = p.id
    JOIN place pl ON p.location_city_id = pl.id
    WHERE pl.name = 'New York'
)
SELECT
    fm.forum_id,
    fm.forum_title,
    fm.first_name,
    fm.last_name,
    fm.moderator_city_name,
    COALESCE(m.member_count, 0)                     AS member_count,
    COALESCE(ps.post_count, 0)                     AS post_count,
    COALESCE(cs.comment_count, 0)                  AS comment_count,
    COALESCE(ps.post_like_count, 0)                AS post_like_count,
    COALESCE(cs.comment_like_count, 0)             AS comment_like_count,
    COALESCE(ts.distinct_tag_count, 0)             AS distinct_tag_count,
    COALESCE(ps.total_post_length, 0)              AS total_post_length,
    COALESCE(cs.total_comment_length, 0)           AS total_comment_length,
    (COALESCE(ps.post_like_count, 0) + COALESCE(cs.comment_like_count, 0)) AS total_likes,
    (COALESCE(ps.post_count, 0) + COALESCE(cs.comment_count, 0))               AS total_content_items,
    CASE WHEN (COALESCE(ps.post_count, 0) + COALESCE(cs.comment_count, 0)) > 0
         THEN (COALESCE(ps.post_like_count, 0) + COALESCE(cs.comment_like_count, 0)) * 1.0 /
              (COALESCE(ps.post_count, 0) + COALESCE(cs.comment_count, 0))
         ELSE 0 END                                 AS avg_likes_per_item
FROM forum_moderator_info fm
LEFT JOIN forum_member_counts   m  ON m.forum_id = fm.forum_id
LEFT JOIN forum_post_stats      ps ON ps.forum_id = fm.forum_id
LEFT JOIN forum_comment_stats   cs ON cs.forum_id = fm.forum_id
LEFT JOIN forum_tag_counts      ts ON ts.forum_id = fm.forum_id
ORDER BY total_likes DESC
LIMIT 10
