/*
  Analytical query: For each organisation (type + name) and the country where it is located,
  count the comments that were made from that same country on posts that are also located
  in a (possibly different) country.  The query returns the organisation details, the
  comment‑origin country, the post‑origin country, total comment count, average comment
  length and the number of distinct commenters.
*/
WITH comment_post AS (
    SELECT
        c.id                     AS comment_id,
        c.length                 AS comment_length,
        c.creator_person_id      AS comment_creator_id,
        c.location_country_id    AS comment_country_id,
        p.id                     AS post_id,
        p.creator_person_id      AS post_creator_id,
        p.location_country_id    AS post_country_id
    FROM comment c
    JOIN post p
      ON c.parent_post_id = p.id               -- valid join rule
)
SELECT
    o.type                     AS organisation_type,
    o.name                     AS organisation_name,
    pc.name                    AS comment_country_name,
    pp.name                    AS post_country_name,
    COUNT(cp.comment_id)       AS total_comments,
    AVG(cp.comment_length)    AS avg_comment_length,
    COUNT(DISTINCT cp.comment_creator_id) AS distinct_commenters
FROM comment_post cp
JOIN place pc
  ON cp.comment_country_id = pc.id               -- comment.location_country_id = place.id
JOIN place pp
  ON cp.post_country_id = pp.id                  -- post.location_country_id = place.id
JOIN organisation o
  ON o.location_place_id = pc.id                 -- organisation.location_place_id = place.id (same place as comment country)
GROUP BY
    o.type,
    o.name,
    pc.name,
    pp.name
ORDER BY total_comments DESC
LIMIT 10
