WITH posts_agg AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(*) AS num_posts,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.creator_person_id
),
post_likes_given AS (
    SELECT
        pl.person_id AS person_id,
        COUNT(*) AS posts_liked_given
    FROM person_likes_post pl
    GROUP BY pl.person_id
),
post_likes_received AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(DISTINCT pl.person_id) AS post_likes_received
    FROM post p
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY p.creator_person_id
),
comments_agg AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS num_comments,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.creator_person_id
),
comment_likes_given AS (
    SELECT
        cl.person_id AS person_id,
        COUNT(*) AS comments_liked_given
    FROM person_likes_comment cl
    GROUP BY cl.person_id
),
comment_likes_received AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(DISTINCT cl.person_id) AS comment_likes_received
    FROM comment c
    JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY c.creator_person_id
),
forum_membership AS (
    SELECT
        fm.person_id AS person_id,
        COUNT(DISTINCT fm.forum_id) AS num_forums_member
    FROM forum_has_member_person fm
    GROUP BY fm.person_id
),
forum_moderation AS (
    SELECT
        f.moderator_person_id AS person_id,
        COUNT(*) AS num_forums_moderated
    FROM forum f
    GROUP BY f.moderator_person_id
),
companies_worked AS (
    SELECT
        pw.person_id AS person_id,
        COUNT(DISTINCT pw.company_id) AS num_companies
    FROM person_work_at_company pw
    GROUP BY pw.person_id
),
universities_studied AS (
    SELECT
        ps.person_id AS person_id,
        COUNT(DISTINCT ps.university_id) AS num_universities
    FROM person_study_at_university ps
    GROUP BY ps.person_id
)
SELECT
    per.id AS person_id,
    per.first_name,
    per.last_name,
    per.gender,
    COALESCE(pag.num_posts, 0) AS num_posts,
    COALESCE(pag.avg_post_length, 0.0) AS avg_post_length,
    COALESCE(cag.num_comments, 0) AS num_comments,
    COALESCE(cag.avg_comment_length, 0.0) AS avg_comment_length,
    COALESCE(plg.posts_liked_given, 0) AS posts_liked_given,
    COALESCE(clg.comments_liked_given, 0) AS comments_liked_given,
    COALESCE(plr.post_likes_received, 0) AS post_likes_received,
    COALESCE(clr.comment_likes_received, 0) AS comment_likes_received,
    COALESCE(fm.num_forums_member, 0) AS num_forums_member,
    COALESCE(fmod.num_forums_moderated, 0) AS num_forums_moderated,
    COALESCE(cw.num_companies, 0) AS num_companies,
    COALESCE(us.num_universities, 0) AS num_universities,
    (COALESCE(pag.num_posts, 0) + COALESCE(cag.num_comments, 0) + COALESCE(plg.posts_liked_given, 0) + COALESCE(clg.comments_liked_given, 0)) AS total_activity
FROM person per
LEFT JOIN posts_agg pag ON pag.person_id = per.id
LEFT JOIN post_likes_given plg ON plg.person_id = per.id
LEFT JOIN post_likes_received plr ON plr.person_id = per.id
LEFT JOIN comments_agg cag ON cag.person_id = per.id
LEFT JOIN comment_likes_given clg ON clg.person_id = per.id
LEFT JOIN comment_likes_received clr ON clr.person_id = per.id
LEFT JOIN forum_membership fm ON fm.person_id = per.id
LEFT JOIN forum_moderation fmod ON fmod.person_id = per.id
LEFT JOIN companies_worked cw ON cw.person_id = per.id
LEFT JOIN universities_studied us ON us.person_id = per.id
ORDER BY total_activity DESC, per.id
LIMIT 10
