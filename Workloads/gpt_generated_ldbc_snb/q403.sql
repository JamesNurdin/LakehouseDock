WITH comment_tag_likes AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        p.gender AS liker_gender,
        COUNT(*) AS like_count,
        AVG(c.length) AS avg_content_length
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN comment_has_tag_tag cht ON c.id = cht.comment_id
    JOIN tag t ON cht.tag_id = t.id
    JOIN person p ON plc.person_id = p.id
    GROUP BY t.id, t.name, p.gender
),
post_tag_likes AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        p.gender AS liker_gender,
        COUNT(*) AS like_count,
        AVG(pst.length) AS avg_content_length
    FROM person_likes_post plp
    JOIN post pst ON plp.post_id = pst.id
    JOIN post_has_tag_tag pht ON pst.id = pht.post_id
    JOIN tag t ON pht.tag_id = t.id
    JOIN person p ON plp.person_id = p.id
    GROUP BY t.id, t.name, p.gender
),
combined AS (
    SELECT tag_id, tag_name, liker_gender, like_count, avg_content_length FROM comment_tag_likes
    UNION ALL
    SELECT tag_id, tag_name, liker_gender, like_count, avg_content_length FROM post_tag_likes
)
SELECT
    tag_id,
    tag_name,
    liker_gender,
    SUM(like_count) AS total_likes,
    ROUND(AVG(avg_content_length), 2) AS overall_avg_content_length
FROM combined
GROUP BY tag_id, tag_name, liker_gender
ORDER BY total_likes DESC
LIMIT 10
