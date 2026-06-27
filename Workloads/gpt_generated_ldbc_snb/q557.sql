WITH tag_post_likes AS (
    SELECT
        t.id   AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS post_like_cnt
    FROM person_has_interest_tag pit
    JOIN tag t ON pit.tag_id = t.id
    JOIN person p_auth ON pit.person_id = p_auth.id
    JOIN post p ON p.creator_person_id = p_auth.id
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY t.id, t.name
),

tag_comment_likes AS (
    SELECT
        t.id   AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS comment_like_cnt
    FROM person_has_interest_tag pit
    JOIN tag t ON pit.tag_id = t.id
    JOIN person p_auth ON pit.person_id = p_auth.id
    JOIN comment c ON c.creator_person_id = p_auth.id
    JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY t.id, t.name
)
SELECT
    COALESCE(tp.tag_id, tc.tag_id)   AS tag_id,
    COALESCE(tp.tag_name, tc.tag_name) AS tag_name,
    COALESCE(tp.post_like_cnt, 0)   AS post_like_cnt,
    COALESCE(tc.comment_like_cnt, 0) AS comment_like_cnt,
    COALESCE(tp.post_like_cnt, 0) + COALESCE(tc.comment_like_cnt, 0) AS total_like_cnt
FROM tag_post_likes tp
FULL OUTER JOIN tag_comment_likes tc
    ON tp.tag_id = tc.tag_id
ORDER BY total_like_cnt DESC
LIMIT 10
