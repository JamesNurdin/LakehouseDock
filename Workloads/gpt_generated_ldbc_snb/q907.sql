WITH tag_comment_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT c.id) AS total_comments,
        COUNT(DISTINCT CASE WHEN phi.person_id IS NOT NULL THEN c.id END) AS comments_by_interested_creators,
        AVG(c.length) AS avg_comment_length,
        COUNT(plc.person_id) AS total_likes,
        COUNT(DISTINCT plc.person_id) AS distinct_likers
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    LEFT JOIN person p ON c.creator_person_id = p.id
    LEFT JOIN person_has_interest_tag phi ON phi.person_id = p.id AND phi.tag_id = t.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY t.id, t.name
)
SELECT
    tag_id,
    tag_name,
    total_comments,
    comments_by_interested_creators,
    CAST(comments_by_interested_creators AS double) / NULLIF(total_comments, 0) AS interest_creator_ratio,
    avg_comment_length,
    total_likes,
    distinct_likers
FROM tag_comment_stats
ORDER BY total_likes DESC
LIMIT 10
