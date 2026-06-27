/*
   Analytical query: for each tag class, count distinct comments that carry a tag of that class,
   count distinct persons who have expressed interest in a tag of that class, and break the
   person count down by gender. Also compute the average number of comments per interested person.
*/
WITH comment_tag_class AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT cht.comment_id) AS comment_cnt
    FROM comment_has_tag_tag cht
    JOIN tag t
        ON cht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id, tc.name
),
person_interest_agg AS (
    SELECT
        tc.id   AS tag_class_id,
        COUNT(DISTINCT pht.person_id)                         AS person_cnt,
        COUNT(DISTINCT CASE WHEN p.gender = 'male'   THEN p.id END) AS male_cnt,
        COUNT(DISTINCT CASE WHEN p.gender = 'female' THEN p.id END) AS female_cnt
    FROM person_has_interest_tag pht
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    JOIN person p
        ON pht.person_id = p.id
    GROUP BY tc.id
)
SELECT
    ct.tag_class_name,
    ct.comment_cnt,
    COALESCE(pi.person_cnt, 0)  AS person_cnt,
    COALESCE(pi.male_cnt,   0)  AS male_cnt,
    COALESCE(pi.female_cnt, 0)  AS female_cnt,
    CASE
        WHEN COALESCE(pi.person_cnt, 0) = 0 THEN NULL
        ELSE ct.comment_cnt * 1.0 / pi.person_cnt
    END AS comments_per_person
FROM comment_tag_class ct
LEFT JOIN person_interest_agg pi
    ON ct.tag_class_id = pi.tag_class_id
ORDER BY ct.comment_cnt DESC
LIMIT 100
