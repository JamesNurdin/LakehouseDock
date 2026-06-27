/*
   Analytical query: counts of tag usage per tag class (and its parent) across the four
   LDBC SNB entities that can have tags – comments, forums, posts and person interests.
   The query groups by the tag class, joins to its parent class (if any), and reports
   both the number of distinct entities tagged and the total number of tag‑assignments
   for each entity type.
*/
WITH tag_class_hierarchy AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        pc.name AS parent_tag_class_name
    FROM tag_class tc
    LEFT JOIN tag_class pc
        ON tc.subclass_of_tag_class_id = pc.id
),
comment_tag_counts AS (
    SELECT
        t.type_tag_class_id                         AS tag_class_id,
        COUNT(DISTINCT c.comment_id)                AS comment_tagged_comments,
        COUNT(*)                                    AS comment_tag_assignments
    FROM comment_has_tag_tag c
    JOIN tag t
        ON c.tag_id = t.id
    GROUP BY t.type_tag_class_id
),
forum_tag_counts AS (
    SELECT
        t.type_tag_class_id                         AS tag_class_id,
        COUNT(DISTINCT f.forum_id)                  AS forum_tagged_forums,
        COUNT(*)                                    AS forum_tag_assignments
    FROM forum_has_tag_tag f
    JOIN tag t
        ON f.tag_id = t.id
    GROUP BY t.type_tag_class_id
),
post_tag_counts AS (
    SELECT
        t.type_tag_class_id                         AS tag_class_id,
        COUNT(DISTINCT p.post_id)                   AS post_tagged_posts,
        COUNT(*)                                    AS post_tag_assignments
    FROM post_has_tag_tag p
    JOIN tag t
        ON p.tag_id = t.id
    GROUP BY t.type_tag_class_id
),
person_interest_counts AS (
    SELECT
        t.type_tag_class_id                         AS tag_class_id,
        COUNT(DISTINCT pi.person_id)                AS person_tagged_interests,
        COUNT(*)                                    AS person_tag_assignments
    FROM person_has_interest_tag pi
    JOIN tag t
        ON pi.tag_id = t.id
    GROUP BY t.type_tag_class_id
)
SELECT
    h.tag_class_name,
    h.parent_tag_class_name,
    COALESCE(ctc.comment_tagged_comments, 0)   AS comment_tagged_comments,
    COALESCE(ctc.comment_tag_assignments, 0)  AS comment_tag_assignments,
    COALESCE(ftc.forum_tagged_forums, 0)      AS forum_tagged_forums,
    COALESCE(ftc.forum_tag_assignments, 0)    AS forum_tag_assignments,
    COALESCE(ptc.post_tagged_posts, 0)        AS post_tagged_posts,
    COALESCE(ptc.post_tag_assignments, 0)     AS post_tag_assignments,
    COALESCE(pitc.person_tagged_interests, 0) AS person_tagged_interests,
    COALESCE(pitc.person_tag_assignments, 0)  AS person_tag_assignments
FROM tag_class_hierarchy h
LEFT JOIN comment_tag_counts      ctc  ON h.tag_class_id = ctc.tag_class_id
LEFT JOIN forum_tag_counts        ftc  ON h.tag_class_id = ftc.tag_class_id
LEFT JOIN post_tag_counts         ptc  ON h.tag_class_id = ptc.tag_class_id
LEFT JOIN person_interest_counts  pitc ON h.tag_class_id = pitc.tag_class_id
ORDER BY h.tag_class_name
