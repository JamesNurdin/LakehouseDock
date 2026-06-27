/*
  Analytical query: For each tag class, count the number of distinct posts and comments that are tagged with tags belonging to that class,
  count the distinct creators of those posts and comments, and count the distinct persons who have expressed interest in tags of that class.
  The results are ordered by the number of posts (descending) and limited to the top 100 tag classes.
*/
SELECT
    tc.id   AS tag_class_id,
    tc.name AS tag_class_name,
    COALESCE(p.post_count, 0)                     AS post_count,
    COALESCE(p.distinct_post_creators, 0)         AS distinct_post_creators,
    COALESCE(c.comment_count, 0)                 AS comment_count,
    COALESCE(c.distinct_comment_creators, 0)     AS distinct_comment_creators,
    COALESCE(i.distinct_interested_persons, 0)   AS distinct_interested_persons
FROM tag_class tc
LEFT JOIN (
    SELECT
        tc.id                                      AS tag_class_id,
        COUNT(DISTINCT p.id)                       AS post_count,
        COUNT(DISTINCT p.creator_person_id)        AS distinct_post_creators
    FROM post p
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    JOIN tag t                ON t.id = pht.tag_id
    JOIN tag_class tc         ON tc.id = t.type_tag_class_id
    GROUP BY tc.id
) p ON p.tag_class_id = tc.id
LEFT JOIN (
    SELECT
        tc.id                                      AS tag_class_id,
        COUNT(DISTINCT c.id)                       AS comment_count,
        COUNT(DISTINCT c.creator_person_id)        AS distinct_comment_creators
    FROM comment c
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    JOIN tag t                 ON t.id = cht.tag_id
    JOIN tag_class tc          ON tc.id = t.type_tag_class_id
    GROUP BY tc.id
) c ON c.tag_class_id = tc.id
LEFT JOIN (
    SELECT
        tc.id                                      AS tag_class_id,
        COUNT(DISTINCT ph.person_id)               AS distinct_interested_persons
    FROM person_has_interest_tag ph
    JOIN tag t               ON t.id = ph.tag_id
    JOIN tag_class tc        ON tc.id = t.type_tag_class_id
    GROUP BY tc.id
) i ON i.tag_class_id = tc.id
ORDER BY post_count DESC
LIMIT 100
