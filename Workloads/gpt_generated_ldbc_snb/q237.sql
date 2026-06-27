WITH member_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
post_stats AS (
    SELECT
        fmp.forum_id,
        COUNT(DISTINCT po.id) AS post_count,
        AVG(po.length) AS avg_post_length
    FROM forum_has_member_person fmp
    JOIN person p ON fmp.person_id = p.id
    JOIN post po ON po.creator_person_id = p.id
    GROUP BY fmp.forum_id
),
likes_stats AS (
    SELECT
        fmp.forum_id,
        COUNT(plp.person_id) AS total_likes
    FROM person_likes_post plp
    JOIN post po ON plp.post_id = po.id
    JOIN person p ON po.creator_person_id = p.id
    JOIN forum_has_member_person fmp ON fmp.person_id = p.id
    GROUP BY fmp.forum_id
)
SELECT
    mc.forum_id,
    mc.member_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ls.total_likes, 0) AS total_likes,
    ps.avg_post_length
FROM member_counts mc
LEFT JOIN post_stats ps ON mc.forum_id = ps.forum_id
LEFT JOIN likes_stats ls ON mc.forum_id = ls.forum_id
ORDER BY mc.forum_id
