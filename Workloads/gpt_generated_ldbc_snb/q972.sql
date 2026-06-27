WITH comment_stats AS (
    SELECT
        id AS comment_id,
        creator_person_id,
        length
    FROM comment
),
likes_per_comment AS (
    SELECT
        comment_id,
        COUNT(*) AS likes_cnt
    FROM person_likes_comment
    GROUP BY comment_id
),
comment_with_likes AS (
    SELECT
        cs.creator_person_id,
        cs.length,
        COALESCE(lpc.likes_cnt, 0) AS likes_cnt
    FROM comment_stats cs
    LEFT JOIN likes_per_comment lpc
        ON cs.comment_id = lpc.comment_id
),
creator_agg AS (
    SELECT
        creator_person_id AS person_id,
        COUNT(*) AS comment_cnt,
        SUM(length) AS total_length,
        AVG(length) AS avg_length,
        SUM(likes_cnt) AS total_likes
    FROM comment_with_likes
    GROUP BY creator_person_id
),
distinct_likers_per_creator AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(DISTINCT plc.person_id) AS distinct_likers
    FROM comment c
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.creator_person_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COUNT(DISTINCT fmp.person_id) AS member_count,
    COALESCE(SUM(ca.comment_cnt), 0) AS total_comments_by_members,
    COALESCE(SUM(ca.total_length), 0) AS total_length_by_members,
    CASE WHEN SUM(ca.comment_cnt) > 0
        THEN CAST(SUM(ca.total_length) AS double) / SUM(ca.comment_cnt)
        ELSE NULL
    END AS avg_length_by_members,
    COALESCE(SUM(ca.total_likes), 0) AS total_likes_on_members_comments,
    COALESCE(SUM(dlc.distinct_likers), 0) AS total_distinct_likers_on_members_comments
FROM forum f
JOIN forum_has_member_person fmp
    ON fmp.forum_id = f.id
JOIN person p
    ON fmp.person_id = p.id
LEFT JOIN creator_agg ca
    ON ca.person_id = p.id
LEFT JOIN distinct_likers_per_creator dlc
    ON dlc.person_id = p.id
GROUP BY f.id, f.title
ORDER BY total_likes_on_members_comments DESC
LIMIT 10
