WITH
    member_counts AS (
        SELECT f.id AS forum_id,
               count(DISTINCT p.id) AS member_count
        FROM forum f
        JOIN forum_has_member_person fmp ON fmp.forum_id = f.id
        JOIN person p ON fmp.person_id = p.id
        GROUP BY f.id
    ),
    comment_stats AS (
        SELECT f.id AS forum_id,
               count(DISTINCT c.id) AS comment_count,
               avg(c.length) AS avg_comment_length
        FROM forum f
        JOIN forum_has_member_person fmp ON fmp.forum_id = f.id
        JOIN person p ON fmp.person_id = p.id
        JOIN comment c ON c.creator_person_id = p.id
        GROUP BY f.id
    ),
    comment_likes AS (
        SELECT f.id AS forum_id,
               count(plc.person_id) AS total_comment_likes
        FROM forum f
        JOIN forum_has_member_person fmp ON fmp.forum_id = f.id
        JOIN person p ON fmp.person_id = p.id
        JOIN comment c ON c.creator_person_id = p.id
        JOIN person_likes_comment plc ON plc.comment_id = c.id
        GROUP BY f.id
    ),
    member_tags AS (
        SELECT f.id AS forum_id,
               count(DISTINCT pht.tag_id) AS distinct_member_tags
        FROM forum f
        JOIN forum_has_member_person fmp ON fmp.forum_id = f.id
        JOIN person p ON fmp.person_id = p.id
        JOIN person_has_interest_tag pht ON pht.person_id = p.id
        GROUP BY f.id
    )
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date,
    m.first_name AS moderator_first_name,
    m.last_name AS moderator_last_name,
    mc.member_count,
    cs.comment_count,
    cs.avg_comment_length,
    cl.total_comment_likes,
    CASE WHEN cs.comment_count > 0 THEN (cl.total_comment_likes * 1.0) / cs.comment_count ELSE 0 END AS avg_likes_per_comment,
    mt.distinct_member_tags
FROM forum f
LEFT JOIN member_counts mc ON mc.forum_id = f.id
LEFT JOIN comment_stats cs ON cs.forum_id = f.id
LEFT JOIN comment_likes cl ON cl.forum_id = f.id
LEFT JOIN member_tags mt ON mt.forum_id = f.id
LEFT JOIN person m ON f.moderator_person_id = m.id
ORDER BY mc.member_count DESC NULLS LAST
LIMIT 10
