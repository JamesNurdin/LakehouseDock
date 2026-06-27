WITH forum_member_counts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id, f.title
),

forum_member_likes AS (
    SELECT
        fm.forum_id,
        COUNT(plp.post_id) AS total_likes
    FROM forum_has_member_person fm
    JOIN person p ON p.id = fm.person_id
    JOIN person_likes_post plp ON plp.person_id = p.id
    GROUP BY fm.forum_id
),

forum_company_counts AS (
    SELECT
        fm.forum_id,
        o.name AS company_name,
        COUNT(*) AS member_cnt
    FROM forum_has_member_person fm
    JOIN person p ON p.id = fm.person_id
    JOIN person_work_at_company pwc ON pwc.person_id = p.id
    JOIN organisation o ON o.id = pwc.company_id
    GROUP BY fm.forum_id, o.name
),

forum_top_3_companies AS (
    SELECT
        forum_id,
        array_agg(company_name ORDER BY member_cnt DESC) AS top_companies
    FROM (
        SELECT
            forum_id,
            company_name,
            member_cnt,
            row_number() OVER (PARTITION BY forum_id ORDER BY member_cnt DESC) AS rn
        FROM forum_company_counts
    ) ranked
    WHERE rn <= 3
    GROUP BY forum_id
),

forum_moderator AS (
    SELECT
        f.id AS forum_id,
        p.first_name AS moderator_first_name,
        p.last_name AS moderator_last_name
    FROM forum f
    JOIN person p ON p.id = f.moderator_person_id
)

SELECT
    fm.forum_id,
    fm.forum_title,
    fm.member_count,
    COALESCE(fl.total_likes, 0) AS total_likes_by_members,
    COALESCE(ftc.top_companies, CAST(ARRAY[] AS array(varchar))) AS top_3_companies,
    fm_mod.moderator_first_name,
    fm_mod.moderator_last_name
FROM forum_member_counts fm
LEFT JOIN forum_member_likes fl ON fl.forum_id = fm.forum_id
LEFT JOIN forum_top_3_companies ftc ON ftc.forum_id = fm.forum_id
LEFT JOIN forum_moderator fm_mod ON fm_mod.forum_id = fm.forum_id
ORDER BY fm.member_count DESC
LIMIT 10
