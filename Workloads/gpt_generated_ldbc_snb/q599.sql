WITH post_tag_likes AS (
    SELECT
        pht.tag_id,
        p.id AS post_id,
        p.creator_person_id AS creator_person_id,
        COUNT(DISTINCT plp.person_id) AS like_count
    FROM post p
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY pht.tag_id, p.id, p.creator_person_id
),
comment_tag_likes AS (
    SELECT
        cht.tag_id,
        c.id AS comment_id,
        c.creator_person_id AS creator_person_id,
        COUNT(DISTINCT plc.person_id) AS like_count
    FROM comment c
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY cht.tag_id, c.id, c.creator_person_id
),
combined AS (
    SELECT
        tag_id,
        creator_person_id,
        like_count
    FROM post_tag_likes
    UNION ALL
    SELECT
        tag_id,
        creator_person_id,
        like_count
    FROM comment_tag_likes
)
SELECT
    t.name AS tag_name,
    COUNT(*) AS tag_occurrences,
    COUNT(DISTINCT combined.creator_person_id) AS distinct_creators,
    SUM(combined.like_count) AS total_likes
FROM combined
JOIN tag t ON t.id = combined.tag_id
GROUP BY t.name
ORDER BY total_likes DESC
LIMIT 10
