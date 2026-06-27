WITH forum_members AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT CASE WHEN i.tag_id IS NOT NULL THEN fm.person_id END) AS member_with_interest_count,
        COUNT(DISTINCT CASE WHEN su.university_id IS NOT NULL THEN fm.person_id END) AS member_with_university_count,
        COUNT(DISTINCT CASE WHEN wc.company_id IS NOT NULL THEN fm.person_id END) AS member_with_company_count
    FROM forum_has_member_person fm
    LEFT JOIN person p ON p.id = fm.person_id
    LEFT JOIN person_has_interest_tag i ON i.person_id = p.id
    LEFT JOIN person_study_at_university su ON su.person_id = p.id
    LEFT JOIN person_work_at_company wc ON wc.person_id = p.id
    GROUP BY fm.forum_id
),
moderator_info AS (
    SELECT
        f.id AS forum_id,
        p.gender AS moderator_gender
    FROM forum f
    LEFT JOIN person p ON p.id = f.moderator_person_id
),
post_metrics AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(DISTINCT po.id) AS post_count,
        AVG(po.length) AS avg_post_length
    FROM post po
    GROUP BY po.container_forum_id
),
post_likes AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(DISTINCT plp.person_id) AS post_like_count
    FROM post po
    LEFT JOIN person_likes_post plp ON plp.post_id = po.id
    GROUP BY po.container_forum_id
),
comment_metrics AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post po ON po.id = c.parent_post_id
    GROUP BY po.container_forum_id
),
comment_likes AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(DISTINCT plc.person_id) AS comment_like_count
    FROM comment c
    JOIN post po ON po.id = c.parent_post_id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY po.container_forum_id
),
member_knows AS (
    SELECT
        fm1.forum_id,
        COUNT(DISTINCT p1.id) AS member_knows_count
    FROM person_knows_person pkp
    JOIN person p1 ON p1.id = pkp.person1_id
    JOIN forum_has_member_person fm1 ON fm1.person_id = p1.id
    JOIN person p2 ON p2.id = pkp.person2_id
    JOIN forum_has_member_person fm2 ON fm2.person_id = p2.id AND fm2.forum_id = fm1.forum_id
    GROUP BY fm1.forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    mi.moderator_gender,
    COALESCE(fm.member_count, 0) AS member_count,
    COALESCE(fm.member_with_interest_count, 0) AS members_with_interest_tag,
    COALESCE(fm.member_with_university_count, 0) AS members_with_university,
    COALESCE(fm.member_with_company_count, 0) AS members_with_company,
    COALESCE(mk.member_knows_count, 0) AS members_who_know_someone_in_forum,
    COALESCE(pm.post_count, 0) AS post_count,
    pm.avg_post_length,
    COALESCE(pl.post_like_count, 0) AS post_like_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    cm.avg_comment_length,
    COALESCE(cl.comment_like_count, 0) AS comment_like_count,
    CASE WHEN COALESCE(pm.post_count, 0) > 0 THEN CAST(COALESCE(pl.post_like_count, 0) AS double) / pm.post_count ELSE NULL END AS avg_likes_per_post,
    CASE WHEN COALESCE(cm.comment_count, 0) > 0 THEN CAST(COALESCE(cl.comment_like_count, 0) AS double) / cm.comment_count ELSE NULL END AS avg_likes_per_comment
FROM forum f
LEFT JOIN forum_members fm ON fm.forum_id = f.id
LEFT JOIN moderator_info mi ON mi.forum_id = f.id
LEFT JOIN post_metrics pm ON pm.forum_id = f.id
LEFT JOIN post_likes pl ON pl.forum_id = f.id
LEFT JOIN comment_metrics cm ON cm.forum_id = f.id
LEFT JOIN comment_likes cl ON cl.forum_id = f.id
LEFT JOIN member_knows mk ON mk.forum_id = f.id
ORDER BY member_count DESC
LIMIT 10
