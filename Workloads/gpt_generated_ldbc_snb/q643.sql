WITH tag_likes AS (
    SELECT
        phit.person_id,
        phit.tag_id,
        plc.comment_id AS liked_id,
        'comment' AS like_type
    FROM person_has_interest_tag phit
    JOIN person p ON phit.person_id = p.id
    JOIN person_likes_comment plc ON p.id = plc.person_id

    UNION ALL

    SELECT
        phit.person_id,
        phit.tag_id,
        plp.post_id AS liked_id,
        'post' AS like_type
    FROM person_has_interest_tag phit
    JOIN person p ON phit.person_id = p.id
    JOIN person_likes_post plp ON p.id = plp.person_id
)

SELECT
    tag_id,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT person_id) AS distinct_likers,
    SUM(CASE WHEN like_type = 'comment' THEN 1 ELSE 0 END) AS comment_likes,
    SUM(CASE WHEN like_type = 'post' THEN 1 ELSE 0 END) AS post_likes
FROM tag_likes
GROUP BY tag_id
ORDER BY total_likes DESC
LIMIT 10
