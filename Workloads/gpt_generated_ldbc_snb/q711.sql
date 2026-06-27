WITH comments_written AS (
    SELECT
        creator_person_id AS person_id,
        COUNT(*) AS total_comments_written,
        AVG(length) AS avg_comment_length
    FROM comment
    GROUP BY creator_person_id
),
comments_liked AS (
    SELECT
        person_id,
        COUNT(*) AS total_comments_liked
    FROM person_likes_comment
    GROUP BY person_id
),
posts_written AS (
    SELECT
        creator_person_id AS person_id,
        COUNT(*) AS total_posts_written,
        AVG(length) AS avg_post_length
    FROM post
    GROUP BY creator_person_id
),
interest_tags AS (
    SELECT
        person_id,
        COUNT(DISTINCT tag_id) AS distinct_interest_tags
    FROM person_has_interest_tag
    GROUP BY person_id
),
forum_membership AS (
    SELECT
        person_id,
        COUNT(DISTINCT forum_id) AS distinct_forums
    FROM forum_has_member_person
    GROUP BY person_id
),
friends AS (
    SELECT
        person1_id AS person_id,
        COUNT(DISTINCT person2_id) AS distinct_friends
    FROM person_knows_person
    GROUP BY person1_id
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    p.gender,
    p.email,
    COALESCE(cw.total_comments_written, 0) AS total_comments_written,
    COALESCE(cw.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cl.total_comments_liked, 0) AS total_comments_liked,
    COALESCE(pw.total_posts_written, 0) AS total_posts_written,
    COALESCE(pw.avg_post_length, 0) AS avg_post_length,
    COALESCE(it.distinct_interest_tags, 0) AS distinct_interest_tags,
    COALESCE(fm.distinct_forums, 0) AS distinct_forums,
    COALESCE(fr.distinct_friends, 0) AS distinct_friends
FROM person p
LEFT JOIN comments_written cw ON p.id = cw.person_id
LEFT JOIN comments_liked cl ON p.id = cl.person_id
LEFT JOIN posts_written pw ON p.id = pw.person_id
LEFT JOIN interest_tags it ON p.id = it.person_id
LEFT JOIN forum_membership fm ON p.id = fm.person_id
LEFT JOIN friends fr ON p.id = fr.person_id
ORDER BY total_comments_written DESC
LIMIT 100
