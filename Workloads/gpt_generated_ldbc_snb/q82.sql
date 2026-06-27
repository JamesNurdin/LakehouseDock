WITH
post_metrics AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
comment_metrics AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
member_counts AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id
),
participant_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT participant_id) AS participant_count
    FROM (
        SELECT
            f.id AS forum_id,
            p.creator_person_id AS participant_id
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        UNION ALL
        SELECT
            f.id AS forum_id,
            c.creator_person_id AS participant_id
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN comment c ON c.parent_post_id = p.id
    )
    GROUP BY forum_id
),
forum_top_tag AS (
    SELECT
        forum_id,
        tag_id AS top_interest_tag_id,
        interest_count
    FROM (
        SELECT
            fm.forum_id AS forum_id,
            pit.tag_id,
            COUNT(DISTINCT pit.person_id) AS interest_count,
            ROW_NUMBER() OVER (PARTITION BY fm.forum_id ORDER BY COUNT(DISTINCT pit.person_id) DESC) AS rn
        FROM forum_has_member_person fm
        JOIN person p ON p.id = fm.person_id
        JOIN person_has_interest_tag pit ON pit.person_id = p.id
        GROUP BY fm.forum_id, pit.tag_id
    ) t
    WHERE rn = 1
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.avg_post_length, 0) AS avg_post_length,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(pc.participant_count, 0) AS participant_count,
    ft.top_interest_tag_id,
    ft.interest_count AS top_interest_tag_member_count
FROM forum f
LEFT JOIN post_metrics pm ON pm.forum_id = f.id
LEFT JOIN comment_metrics cm ON cm.forum_id = f.id
LEFT JOIN member_counts mc ON mc.forum_id = f.id
LEFT JOIN participant_counts pc ON pc.forum_id = f.id
LEFT JOIN forum_top_tag ft ON ft.forum_id = f.id
ORDER BY post_count DESC
LIMIT 10
