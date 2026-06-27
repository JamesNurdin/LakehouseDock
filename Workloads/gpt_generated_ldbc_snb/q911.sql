WITH post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creator_count
    FROM post p
    GROUP BY p.container_forum_id
),
tag_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT i.tag_id) AS distinct_creator_tag_count
    FROM post p
    JOIN person c
      ON p.creator_person_id = c.id
    JOIN person_has_interest_tag i
      ON i.person_id = c.id
    GROUP BY p.container_forum_id
),
country_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT pl.id) AS distinct_post_country_count
    FROM post p
    JOIN place pl
      ON p.location_country_id = pl.id
    GROUP BY p.container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    m.first_name AS moderator_first_name,
    m.last_name AS moderator_last_name,
    ps.post_count,
    ps.avg_post_length,
    ps.distinct_creator_count,
    ts.distinct_creator_tag_count,
    cs.distinct_post_country_count
FROM forum f
JOIN person m
  ON f.moderator_person_id = m.id
LEFT JOIN post_stats ps
  ON ps.forum_id = f.id
LEFT JOIN tag_stats ts
  ON ts.forum_id = f.id
LEFT JOIN country_stats cs
  ON cs.forum_id = f.id
ORDER BY ps.post_count DESC
LIMIT 10
