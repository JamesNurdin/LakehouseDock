/*
  Top tags by total likes on comments, broken down by the gender of the comment creator
  and, when the comment is a reply, the gender of the parent‑comment creator.
*/
WITH comment_tag_likes AS (
    SELECT
        c_tag.tag_id,
        c.id AS comment_id,
        c.length,
        p.gender AS creator_gender,
        plc.person_id AS liker_id,
        CASE WHEN c.parent_comment_id IS NOT NULL THEN true ELSE false END AS is_reply,
        p_parent.gender AS parent_creator_gender
    FROM comment_has_tag_tag c_tag
    JOIN comment c
        ON c_tag.comment_id = c.id
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    JOIN person p
        ON c.creator_person_id = p.id
    LEFT JOIN comment pc
        ON c.parent_comment_id = pc.id
    LEFT JOIN person p_parent
        ON pc.creator_person_id = p_parent.id
)
SELECT
    tag_id,
    creator_gender,
    parent_creator_gender,
    COUNT(*) AS like_count,
    COUNT(DISTINCT comment_id) AS distinct_commented_liked,
    AVG(length) AS avg_comment_length,
    SUM(CASE WHEN is_reply THEN 1 ELSE 0 END) AS reply_like_count
FROM comment_tag_likes
GROUP BY tag_id, creator_gender, parent_creator_gender
ORDER BY like_count DESC
LIMIT 10
