/*
  Total likes on posts and comments, broken down by tag class and the gender of the person who liked the content.
  The query aggregates likes from both posts and comments, then combines the results so you can see the
  overall popularity of each tag class per gender.
*/
WITH post_likes AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        p.gender,
        COUNT(*) AS post_like_cnt
    FROM person_likes_post plp
    JOIN post po
        ON plp.post_id = po.id
    JOIN post_has_tag_tag pht
        ON po.id = pht.post_id
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    JOIN person p
        ON plp.person_id = p.id
    GROUP BY tc.id, tc.name, p.gender
),
comment_likes AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        p.gender,
        COUNT(*) AS comment_like_cnt
    FROM person_likes_comment plc
    JOIN comment c
        ON plc.comment_id = c.id
    JOIN comment_has_tag_tag cht
        ON c.id = cht.comment_id
    JOIN tag t
        ON cht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    JOIN person p
        ON plc.person_id = p.id
    GROUP BY tc.id, tc.name, p.gender
)
SELECT
    COALESCE(pl.tag_class_id, cl.tag_class_id)       AS tag_class_id,
    COALESCE(pl.tag_class_name, cl.tag_class_name) AS tag_class_name,
    COALESCE(pl.gender, cl.gender)                 AS gender,
    COALESCE(pl.post_like_cnt, 0) + COALESCE(cl.comment_like_cnt, 0) AS total_likes
FROM post_likes pl
FULL OUTER JOIN comment_likes cl
    ON pl.tag_class_id = cl.tag_class_id
   AND pl.gender = cl.gender
ORDER BY total_likes DESC
LIMIT 20
