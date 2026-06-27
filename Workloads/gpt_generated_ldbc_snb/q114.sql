/*
  Analytical query: Top tags by total activity (comments, forums, and person interests).
  Shows per‑tag counts of distinct comments, forums, and male/female persons interested.
*/
WITH comment_counts AS (
    SELECT
        cht.tag_id,
        COUNT(DISTINCT cht.comment_id) AS comment_cnt
    FROM comment_has_tag_tag cht
    GROUP BY cht.tag_id
),
forum_counts AS (
    SELECT
        fht.tag_id,
        COUNT(DISTINCT fht.forum_id) AS forum_cnt
    FROM forum_has_tag_tag fht
    GROUP BY fht.tag_id
),
person_interest_counts AS (
    SELECT
        pit.tag_id,
        p.gender,
        COUNT(DISTINCT pit.person_id) AS person_cnt
    FROM person_has_interest_tag pit
    JOIN person p ON pit.person_id = p.id
    GROUP BY pit.tag_id, p.gender
),
tag_info AS (
    SELECT
        t.id   AS tag_id,
        t.name AS tag_name,
        t.type_tag_class_id
    FROM tag t
)
SELECT
    ti.tag_id,
    ti.tag_name,
    COALESCE(cc.comment_cnt, 0) AS comment_cnt,
    COALESCE(fc.forum_cnt, 0)   AS forum_cnt,
    COALESCE(pm.person_cnt, 0)  AS male_person_cnt,
    COALESCE(pf.person_cnt, 0)  AS female_person_cnt,
    (COALESCE(cc.comment_cnt, 0) + COALESCE(fc.forum_cnt, 0) + COALESCE(pm.person_cnt, 0) + COALESCE(pf.person_cnt, 0)) AS total_interactions
FROM tag_info ti
LEFT JOIN comment_counts cc ON cc.tag_id = ti.tag_id
LEFT JOIN forum_counts   fc ON fc.tag_id = ti.tag_id
LEFT JOIN person_interest_counts pm ON pm.tag_id = ti.tag_id AND pm.gender = 'male'
LEFT JOIN person_interest_counts pf ON pf.tag_id = ti.tag_id AND pf.gender = 'female'
ORDER BY total_interactions DESC
LIMIT 10
