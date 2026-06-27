WITH forum_member_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(*) AS member_total,
        COUNT(CASE WHEN p.gender = 'male' THEN 1 END) AS male_members,
        COUNT(CASE WHEN p.gender = 'female' THEN 1 END) AS female_members,
        AVG(p_work.work_from) AS avg_work_from_year
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    JOIN person p ON fm.person_id = p.id
    LEFT JOIN person_work_at_company p_work ON p_work.person_id = p.id
    GROUP BY f.id, f.title
),
forum_post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
forum_comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        SUM(c.length) AS total_comment_length,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_post_like_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_like_count,
        COUNT(DISTINCT plp.person_id) AS distinct_post_likers
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comment_like_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_like_count,
        COUNT(DISTINCT plc.person_id) AS distinct_comment_likers
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_total_likers AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS distinct_total_likers
    FROM (
        SELECT p.container_forum_id AS forum_id, plp.person_id
        FROM person_likes_post plp
        JOIN post p ON plp.post_id = p.id
        UNION ALL
        SELECT p.container_forum_id AS forum_id, plc.person_id
        FROM person_likes_comment plc
        JOIN comment c ON plc.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
    ) t
    GROUP BY forum_id
)
SELECT
    fms.forum_id,
    fms.forum_title,
    fms.member_total,
    fms.male_members,
    fms.female_members,
    fms.avg_work_from_year,
    COALESCE(fps.post_count, 0) AS post_count,
    COALESCE(fps.total_post_length, 0) AS total_post_length,
    COALESCE(fps.avg_post_length, 0) AS avg_post_length,
    COALESCE(fcs.comment_count, 0) AS comment_count,
    COALESCE(fcs.total_comment_length, 0) AS total_comment_length,
    COALESCE(fcs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(fpls.post_like_count, 0) AS post_like_count,
    COALESCE(fpls.distinct_post_likers, 0) AS distinct_post_likers,
    COALESCE(fcls.comment_like_count, 0) AS comment_like_count,
    COALESCE(fcls.distinct_comment_likers, 0) AS distinct_comment_likers,
    COALESCE(fpls.post_like_count, 0) + COALESCE(fcls.comment_like_count, 0) AS total_like_count,
    COALESCE(ftl.distinct_total_likers, 0) AS distinct_total_likers
FROM forum_member_stats fms
LEFT JOIN forum_post_stats fps ON fps.forum_id = fms.forum_id
LEFT JOIN forum_comment_stats fcs ON fcs.forum_id = fms.forum_id
LEFT JOIN forum_post_like_stats fpls ON fpls.forum_id = fms.forum_id
LEFT JOIN forum_comment_like_stats fcls ON fcls.forum_id = fms.forum_id
LEFT JOIN forum_total_likers ftl ON ftl.forum_id = fms.forum_id
ORDER BY fms.member_total DESC
LIMIT 100
