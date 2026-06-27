WITH comment_stats AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.creator_person_id
),
post_stats AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.creator_person_id
),
likes_comment_stats AS (
    SELECT
        plc.person_id,
        COUNT(*) AS comment_likes
    FROM person_likes_comment plc
    GROUP BY plc.person_id
),
likes_post_stats AS (
    SELECT
        plp.person_id,
        COUNT(*) AS post_likes
    FROM person_likes_post plp
    GROUP BY plp.person_id
),
interest_stats AS (
    SELECT
        phi.person_id,
        COUNT(DISTINCT phi.tag_id) AS distinct_interest_tags
    FROM person_has_interest_tag phi
    GROUP BY phi.person_id
),
friend_stats AS (
    SELECT
        f.person_id,
        COUNT(DISTINCT f.friend_id) AS friend_count
    FROM (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) f
    GROUP BY f.person_id
),
work_stats AS (
    SELECT
        pwac.person_id,
        COUNT(DISTINCT pwac.company_id) AS distinct_companies,
        MIN(pwac.work_from) AS earliest_work_year,
        MAX(pwac.work_from) AS latest_work_year
    FROM person_work_at_company pwac
    GROUP BY pwac.person_id
)
SELECT
    per.id AS person_id,
    per.first_name,
    per.last_name,
    per.gender,
    per.birthday,
    per.email,
    pl.name AS city_name,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(lc.comment_likes, 0) AS comment_likes,
    COALESCE(lp.post_likes, 0) AS post_likes,
    COALESCE(ints.distinct_interest_tags, 0) AS distinct_interest_tags,
    COALESCE(fs.friend_count, 0) AS friend_count,
    COALESCE(ws.distinct_companies, 0) AS distinct_companies,
    ws.earliest_work_year,
    ws.latest_work_year
FROM person per
LEFT JOIN place pl ON pl.id = per.location_city_id
LEFT JOIN comment_stats cs ON cs.person_id = per.id
LEFT JOIN post_stats ps ON ps.person_id = per.id
LEFT JOIN likes_comment_stats lc ON lc.person_id = per.id
LEFT JOIN likes_post_stats lp ON lp.person_id = per.id
LEFT JOIN interest_stats ints ON ints.person_id = per.id
LEFT JOIN friend_stats fs ON fs.person_id = per.id
LEFT JOIN work_stats ws ON ws.person_id = per.id
ORDER BY comment_likes DESC, post_likes DESC
LIMIT 100
