WITH tag_class_base AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM tag_class AS tc
),
tag_counts AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM tag AS t
    JOIN tag_class AS tc
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
post_counts AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pht.post_id) AS post_count
    FROM post_has_tag_tag AS pht
    JOIN tag AS t
        ON pht.tag_id = t.id
    JOIN tag_class AS tc
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
comment_counts AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT cht.comment_id) AS comment_count
    FROM comment_has_tag_tag AS cht
    JOIN tag AS t
        ON cht.tag_id = t.id
    JOIN tag_class AS tc
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
forum_counts AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT fht.forum_id) AS forum_count
    FROM forum_has_tag_tag AS fht
    JOIN tag AS t
        ON fht.tag_id = t.id
    JOIN tag_class AS tc
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
person_counts AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT p.id) AS person_count,
        COUNT(DISTINCT CASE WHEN p.gender = 'male' THEN p.id END) AS male_person_count,
        COUNT(DISTINCT CASE WHEN p.gender = 'female' THEN p.id END) AS female_person_count
    FROM person_has_interest_tag AS pit
    JOIN person AS p
        ON pit.person_id = p.id
    JOIN tag AS t
        ON pit.tag_id = t.id
    JOIN tag_class AS tc
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
)
SELECT
    tc.tag_class_id,
    tc.tag_class_name,
    COALESCE(tc_cnt.tag_count, 0) AS tag_count,
    COALESCE(p_cnt.post_count, 0) AS post_count,
    COALESCE(c_cnt.comment_count, 0) AS comment_count,
    COALESCE(f_cnt.forum_count, 0) AS forum_count,
    COALESCE(per_cnt.person_count, 0) AS person_count,
    COALESCE(per_cnt.male_person_count, 0) AS male_person_count,
    COALESCE(per_cnt.female_person_count, 0) AS female_person_count
FROM tag_class_base AS tc
LEFT JOIN tag_counts AS tc_cnt
    ON tc.tag_class_id = tc_cnt.tag_class_id
LEFT JOIN post_counts AS p_cnt
    ON tc.tag_class_id = p_cnt.tag_class_id
LEFT JOIN comment_counts AS c_cnt
    ON tc.tag_class_id = c_cnt.tag_class_id
LEFT JOIN forum_counts AS f_cnt
    ON tc.tag_class_id = f_cnt.tag_class_id
LEFT JOIN person_counts AS per_cnt
    ON tc.tag_class_id = per_cnt.tag_class_id
ORDER BY tc.tag_class_name
