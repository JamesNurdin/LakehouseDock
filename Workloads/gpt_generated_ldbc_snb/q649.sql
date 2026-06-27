WITH person_base AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name,
        p.gender,
        p.birthday,
        p.email,
        pl.name AS city_name
    FROM person p
    LEFT JOIN place pl ON p.location_city_id = pl.id
),
posts_created AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(p.id) AS posts_created,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.creator_person_id
),
liked_posts AS (
    SELECT
        plp.person_id,
        COUNT(DISTINCT plp.post_id) AS liked_posts
    FROM person_likes_post plp
    GROUP BY plp.person_id
),
liked_comments AS (
    SELECT
        plc.person_id,
        COUNT(DISTINCT plc.comment_id) AS liked_comments
    FROM person_likes_comment plc
    GROUP BY plc.person_id
),
forum_membership AS (
    SELECT
        fmp.person_id,
        COUNT(DISTINCT fmp.forum_id) AS forums_member_of
    FROM forum_has_member_person fmp
    GROUP BY fmp.person_id
),
interest_tags AS (
    SELECT
        pit.person_id,
        COUNT(DISTINCT pit.tag_id) AS interest_tag_count
    FROM person_has_interest_tag pit
    GROUP BY pit.person_id
),
work_companies AS (
    SELECT
        pwac.person_id,
        COUNT(DISTINCT pwac.company_id) AS companies_worked_for
    FROM person_work_at_company pwac
    GROUP BY pwac.person_id
)
SELECT
    pb.person_id,
    pb.first_name,
    pb.last_name,
    pb.gender,
    pb.birthday,
    pb.email,
    pb.city_name,
    COALESCE(pc.posts_created, 0) AS posts_created,
    COALESCE(pc.total_post_length, 0) AS total_post_length,
    pc.avg_post_length,
    COALESCE(lp.liked_posts, 0) AS liked_posts,
    COALESCE(lc.liked_comments, 0) AS liked_comments,
    COALESCE(fm.forums_member_of, 0) AS forums_member_of,
    COALESCE(it.interest_tag_count, 0) AS interest_tag_count,
    COALESCE(wc.companies_worked_for, 0) AS companies_worked_for
FROM person_base pb
LEFT JOIN posts_created pc ON pc.person_id = pb.person_id
LEFT JOIN liked_posts lp ON lp.person_id = pb.person_id
LEFT JOIN liked_comments lc ON lc.person_id = pb.person_id
LEFT JOIN forum_membership fm ON fm.person_id = pb.person_id
LEFT JOIN interest_tags it ON it.person_id = pb.person_id
LEFT JOIN work_companies wc ON wc.person_id = pb.person_id
ORDER BY posts_created DESC, total_post_length DESC
LIMIT 20
