/*
  Top‑5 tag classes whose tags receive the most likes from users who are
  explicitly interested in those tags. The query joins likes, comments, tags,
  tag classes and the person‑interest relationship, then aggregates per tag class.
*/
WITH liked_comments AS (
    SELECT
        p.id                     AS person_id,
        c.id                     AS comment_id,
        c.length                 AS comment_length,
        t.id                     AS tag_id,
        t.name                   AS tag_name,
        tc.id                    AS tag_class_id,
        tc.name                  AS tag_class_name
    FROM person_likes_comment plc
    JOIN comment c
        ON plc.comment_id = c.id                                   -- person_likes_comment.comment_id = comment.id
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id                                   -- comment_has_tag_tag.comment_id = comment.id
    JOIN tag t
        ON cht.tag_id = t.id                                       -- comment_has_tag_tag.tag_id = tag.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id                             -- tag.type_tag_class_id = tag_class.id
    JOIN person p
        ON plc.person_id = p.id                                    -- person_likes_comment.person_id = person.id
    JOIN person_has_interest_tag pit
        ON pit.person_id = p.id                                    -- person_has_interest_tag.person_id = person.id
        AND pit.tag_id = t.id                                      -- person_has_interest_tag.tag_id = tag.id
)
SELECT
    tag_class_id,
    tag_class_name,
    COUNT(*)                                          AS total_interested_likes,
    COUNT(DISTINCT person_id)                         AS distinct_interested_likers,
    COUNT(DISTINCT comment_id)                        AS distinct_comments,
    CAST(COUNT(*) AS double) / NULLIF(COUNT(DISTINCT comment_id), 0) AS avg_likes_per_comment,
    CAST(SUM(comment_length) AS double) / NULLIF(COUNT(DISTINCT comment_id), 0) AS avg_comment_length
FROM liked_comments
GROUP BY tag_class_id, tag_class_name
ORDER BY avg_likes_per_comment DESC
LIMIT 5
