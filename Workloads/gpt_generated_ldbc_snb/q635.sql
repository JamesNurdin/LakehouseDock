WITH post_tagged AS (
    SELECT
        t.type_tag_class_id AS tag_class_id,
        p.id AS post_id,
        p.creator_person_id AS person_id,
        p.length AS post_length
    FROM post p
    JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    JOIN tag t
        ON t.id = pht.tag_id
),
comment_tagged AS (
    SELECT
        t.type_tag_class_id AS tag_class_id,
        c.id AS comment_id,
        c.creator_person_id AS person_id,
        c.length AS comment_length
    FROM comment c
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    JOIN tag t
        ON t.id = cht.tag_id
),
interest AS (
    SELECT
        t.type_tag_class_id AS tag_class_id,
        pht.person_id AS person_id
    FROM person_has_interest_tag pht
    JOIN tag t
        ON t.id = pht.tag_id
),
tag_class_info AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM tag_class tc
)
SELECT
    tci.tag_class_id,
    tci.tag_class_name,
    COUNT(DISTINCT pt.post_id) AS post_count,
    COUNT(DISTINCT ct.comment_id) AS comment_count,
    COUNT(DISTINCT it.person_id) AS interest_person_count,
    AVG(pt.post_length) AS avg_post_length,
    AVG(ct.comment_length) AS avg_comment_length
FROM tag_class_info tci
LEFT JOIN post_tagged pt
    ON pt.tag_class_id = tci.tag_class_id
LEFT JOIN comment_tagged ct
    ON ct.tag_class_id = tci.tag_class_id
LEFT JOIN interest it
    ON it.tag_class_id = tci.tag_class_id
GROUP BY tci.tag_class_id, tci.tag_class_name
ORDER BY post_count DESC
LIMIT 20
