WITH post_agg AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        COUNT(DISTINCT p.id) AS post_cnt,
        COUNT(pl.person_id) AS post_like_cnt
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    JOIN post p ON p.id = pht.post_id
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY t.id, t.name, tc.name
),
comment_agg AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT c.id) AS comment_cnt,
        COUNT(cl.person_id) AS comment_like_cnt
    FROM tag t
    JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    JOIN comment c ON c.id = cht.comment_id
    LEFT JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY t.id
),
person_agg AS (
    SELECT
        tag_id,
        COUNT(DISTINCT person_id) AS distinct_person_likes
    FROM (
        SELECT
            t.id AS tag_id,
            pl.person_id
        FROM tag t
        JOIN post_has_tag_tag pht ON pht.tag_id = t.id
        JOIN post p ON p.id = pht.post_id
        JOIN person_likes_post pl ON pl.post_id = p.id

        UNION ALL

        SELECT
            t.id AS tag_id,
            cl.person_id
        FROM tag t
        JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
        JOIN comment c ON c.id = cht.comment_id
        JOIN person_likes_comment cl ON cl.comment_id = c.id
    ) AS combined
    GROUP BY tag_id
)
SELECT
    pa.tag_id,
    pa.tag_name,
    pa.tag_class_name,
    pa.post_cnt,
    COALESCE(ca.comment_cnt, 0) AS comment_cnt,
    pa.post_like_cnt,
    COALESCE(ca.comment_like_cnt, 0) AS comment_like_cnt,
    COALESCE(pag.distinct_person_likes, 0) AS distinct_person_likes
FROM post_agg pa
LEFT JOIN comment_agg ca ON ca.tag_id = pa.tag_id
LEFT JOIN person_agg pag ON pag.tag_id = pa.tag_id
ORDER BY pa.post_like_cnt DESC
LIMIT 10
