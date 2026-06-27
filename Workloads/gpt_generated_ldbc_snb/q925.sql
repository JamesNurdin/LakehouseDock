WITH
    post_agg AS (
        SELECT
            creator_person_id AS person_id,
            COUNT(*) AS post_count,
            COALESCE(SUM(length), 0) AS total_post_length,
            AVG(length) AS avg_post_length
        FROM post
        GROUP BY creator_person_id
    ),
    comment_agg AS (
        SELECT
            creator_person_id AS person_id,
            COUNT(*) AS comment_count,
            COALESCE(SUM(length), 0) AS total_comment_length,
            AVG(length) AS avg_comment_length
        FROM comment
        GROUP BY creator_person_id
    ),
    like_agg AS (
        SELECT
            person_id,
            COUNT(*) AS like_count
        FROM person_likes_post
        GROUP BY person_id
    ),
    friend_agg AS (
        SELECT
            person1_id AS person_id,
            COUNT(DISTINCT person2_id) AS friend_count
        FROM person_knows_person
        GROUP BY person1_id
    ),
    interest_agg AS (
        SELECT
            person_id,
            COUNT(DISTINCT tag_id) AS interest_tag_count
        FROM person_has_interest_tag
        GROUP BY person_id
    ),
    city_info AS (
        SELECT
            p.id AS person_id,
            p.first_name,
            p.last_name,
            pl.name AS city_name
        FROM person p
        LEFT JOIN place pl ON p.location_city_id = pl.id
    )
SELECT
    ci.person_id,
    ci.first_name,
    ci.last_name,
    ci.city_name,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(pa.total_post_length, 0) AS total_post_length,
    pa.avg_post_length,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.total_comment_length, 0) AS total_comment_length,
    ca.avg_comment_length,
    COALESCE(la.like_count, 0) AS like_count,
    COALESCE(fa.friend_count, 0) AS friend_count,
    COALESCE(ia.interest_tag_count, 0) AS interest_tag_count
FROM city_info ci
LEFT JOIN post_agg pa ON ci.person_id = pa.person_id
LEFT JOIN comment_agg ca ON ci.person_id = ca.person_id
LEFT JOIN like_agg la ON ci.person_id = la.person_id
LEFT JOIN friend_agg fa ON ci.person_id = fa.person_id
LEFT JOIN interest_agg ia ON ci.person_id = ia.person_id
ORDER BY ci.person_id
LIMIT 100
