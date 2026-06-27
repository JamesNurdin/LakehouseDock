WITH forum_counts AS (
    SELECT
        tag.id AS tag_id,
        COUNT(DISTINCT forum_has_tag_tag.forum_id) AS forum_cnt
    FROM forum_has_tag_tag
    JOIN tag ON forum_has_tag_tag.tag_id = tag.id
    GROUP BY tag.id
),
post_counts AS (
    SELECT
        tag.id AS tag_id,
        COUNT(DISTINCT post_has_tag_tag.post_id) AS post_cnt
    FROM post_has_tag_tag
    JOIN tag ON post_has_tag_tag.tag_id = tag.id
    GROUP BY tag.id
),
person_counts AS (
    SELECT
        tag.id AS tag_id,
        COUNT(DISTINCT person_has_interest_tag.person_id) AS person_cnt
    FROM person_has_interest_tag
    JOIN tag ON person_has_interest_tag.tag_id = tag.id
    GROUP BY tag.id
),
gender_counts AS (
    SELECT
        tag.id AS tag_id,
        COUNT(DISTINCT CASE WHEN person.gender = 'male' THEN person.id END) AS male_cnt,
        COUNT(DISTINCT CASE WHEN person.gender = 'female' THEN person.id END) AS female_cnt
    FROM person_has_interest_tag
    JOIN person ON person_has_interest_tag.person_id = person.id
    JOIN tag ON person_has_interest_tag.tag_id = tag.id
    GROUP BY tag.id
)
SELECT
    t.id,
    t.name,
    COALESCE(f.forum_cnt, 0) AS forum_cnt,
    COALESCE(p.post_cnt, 0) AS post_cnt,
    COALESCE(pc.person_cnt, 0) AS person_cnt,
    COALESCE(g.male_cnt, 0) AS male_cnt,
    COALESCE(g.female_cnt, 0) AS female_cnt,
    (COALESCE(f.forum_cnt, 0) + COALESCE(p.post_cnt, 0) + COALESCE(pc.person_cnt, 0)) AS total_activity,
    CASE WHEN COALESCE(g.female_cnt, 0) = 0 THEN NULL ELSE COALESCE(g.male_cnt, 0) * 1.0 / COALESCE(g.female_cnt, 0) END AS male_female_ratio
FROM tag t
LEFT JOIN forum_counts f ON t.id = f.tag_id
LEFT JOIN post_counts p ON t.id = p.tag_id
LEFT JOIN person_counts pc ON t.id = pc.tag_id
LEFT JOIN gender_counts g ON t.id = g.tag_id
ORDER BY total_activity DESC
LIMIT 50
