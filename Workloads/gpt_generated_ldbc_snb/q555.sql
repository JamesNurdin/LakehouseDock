WITH comment_counts AS (
    SELECT tag_id,
           COUNT(*) AS comment_cnt
    FROM comment_has_tag_tag
    GROUP BY tag_id
),
forum_counts AS (
    SELECT tag_id,
           COUNT(*) AS forum_cnt
    FROM forum_has_tag_tag
    GROUP BY tag_id
),
person_gender_agg AS (
    SELECT pht.tag_id,
           SUM(CASE WHEN p.gender = 'male'   THEN 1 ELSE 0 END) AS male_cnt,
           SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) AS female_cnt,
           SUM(CASE WHEN p.gender NOT IN ('male', 'female') THEN 1 ELSE 0 END) AS other_cnt
    FROM person_has_interest_tag pht
    JOIN person p ON pht.person_id = p.id
    GROUP BY pht.tag_id
)
SELECT t.id,
       t.name,
       t.url,
       t.type_tag_class_id,
       COALESCE(cc.comment_cnt, 0) AS comment_cnt,
       COALESCE(fc.forum_cnt,   0) AS forum_cnt,
       COALESCE(pga.male_cnt,   0) AS male_cnt,
       COALESCE(pga.female_cnt, 0) AS female_cnt,
       COALESCE(pga.other_cnt,  0) AS other_cnt
FROM tag t
LEFT JOIN comment_counts cc   ON t.id = cc.tag_id
LEFT JOIN forum_counts   fc   ON t.id = fc.tag_id
LEFT JOIN person_gender_agg pga ON t.id = pga.tag_id
ORDER BY (
    COALESCE(cc.comment_cnt, 0) +
    COALESCE(fc.forum_cnt,   0) +
    COALESCE(pga.male_cnt,   0) +
    COALESCE(pga.female_cnt, 0) +
    COALESCE(pga.other_cnt,  0)
) DESC
LIMIT 10
