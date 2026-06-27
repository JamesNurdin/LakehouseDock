WITH member_agg AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT CASE WHEN per.gender = 'male' THEN per.id END) AS male_member_count,
        COUNT(DISTINCT CASE WHEN per.gender = 'female' THEN per.id END) AS female_member_count,
        COUNT(DISTINCT pl.name) AS distinct_member_cities,
        COUNT(DISTINCT pit.tag_id) AS distinct_interest_tags
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN person per
        ON per.id = fm.person_id
    LEFT JOIN place pl
        ON per.location_city_id = pl.id
    LEFT JOIN person_has_interest_tag pit
        ON pit.person_id = per.id
    GROUP BY f.id, f.title
),
post_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id
),
like_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT plp.person_id) AS distinct_likers
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY f.id
)
SELECT
    m.forum_id,
    m.forum_title,
    m.member_count,
    m.male_member_count,
    m.female_member_count,
    m.distinct_member_cities,
    m.distinct_interest_tags,
    p.post_count,
    p.avg_post_length,
    l.distinct_likers
FROM member_agg m
LEFT JOIN post_stats p
    ON p.forum_id = m.forum_id
LEFT JOIN like_stats l
    ON l.forum_id = m.forum_id
ORDER BY m.member_count DESC
LIMIT 20
