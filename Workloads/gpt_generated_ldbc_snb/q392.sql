WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           f.moderator_person_id
    FROM forum f
),
forum_mod AS (
    SELECT fb.forum_id,
           fb.forum_title,
           p.first_name AS moderator_first_name,
           p.last_name AS moderator_last_name
    FROM forum_base fb
    JOIN person p ON fb.moderator_person_id = p.id
),
forum_posts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_posts,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
forum_comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_comments
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_likes_posts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_likes_posts
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_likes_comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_likes_comments
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_post_tags AS (
    SELECT p.container_forum_id AS forum_id,
           pt.tag_id
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
),
forum_comment_tags AS (
    SELECT p.container_forum_id AS forum_id,
           ct.tag_id
    FROM comment_has_tag_tag ct
    JOIN comment c ON ct.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
),
forum_all_tags AS (
    SELECT forum_id, tag_id FROM forum_post_tags
    UNION ALL
    SELECT forum_id, tag_id FROM forum_comment_tags
),
forum_tag_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT tag_id) AS total_tags_used
    FROM forum_all_tags
    GROUP BY forum_id
),
forum_members AS (
    SELECT fhm.forum_id,
           COUNT(*) AS total_members
    FROM forum_has_member_person fhm
    GROUP BY fhm.forum_id
),
forum_participant_ids AS (
    SELECT fhm.forum_id, fhm.person_id AS person_id
    FROM forum_has_member_person fhm
    UNION
    SELECT p.container_forum_id AS forum_id, p.creator_person_id AS person_id
    FROM post p
    UNION
    SELECT p.container_forum_id AS forum_id, c.creator_person_id AS person_id
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    UNION
    SELECT p.container_forum_id AS forum_id, plp.person_id AS person_id
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    UNION
    SELECT p.container_forum_id AS forum_id, plc.person_id AS person_id
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
),
forum_participant_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS total_participants
    FROM forum_participant_ids
    GROUP BY forum_id
),
participant_countries AS (
    SELECT fpi.forum_id,
           country.id AS country_id
    FROM forum_participant_ids fpi
    JOIN person per ON fpi.person_id = per.id
    JOIN place city ON per.location_city_id = city.id
    JOIN place country ON city.part_of_place_id = country.id
),
forum_country_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT country_id) AS distinct_participant_countries
    FROM participant_countries
    GROUP BY forum_id
)
SELECT
    fm.forum_id,
    fm.forum_title,
    fm.moderator_first_name,
    fm.moderator_last_name,
    COALESCE(fp.total_posts, 0) AS total_posts,
    COALESCE(fp.avg_post_length, 0) AS avg_post_length,
    COALESCE(fc.total_comments, 0) AS total_comments,
    COALESCE(fl_posts.total_likes_posts, 0) AS total_likes_posts,
    COALESCE(fl_comments.total_likes_comments, 0) AS total_likes_comments,
    COALESCE(ftc.total_tags_used, 0) AS total_tags_used,
    COALESCE(fmbr.total_members, 0) AS total_members,
    COALESCE(fpc.total_participants, 0) AS total_participants,
    COALESCE(fcc.distinct_participant_countries, 0) AS distinct_participant_countries
FROM forum_mod fm
LEFT JOIN forum_posts fp ON fm.forum_id = fp.forum_id
LEFT JOIN forum_comments fc ON fm.forum_id = fc.forum_id
LEFT JOIN forum_likes_posts fl_posts ON fm.forum_id = fl_posts.forum_id
LEFT JOIN forum_likes_comments fl_comments ON fm.forum_id = fl_comments.forum_id
LEFT JOIN forum_tag_counts ftc ON fm.forum_id = ftc.forum_id
LEFT JOIN forum_members fmbr ON fm.forum_id = fmbr.forum_id
LEFT JOIN forum_participant_counts fpc ON fm.forum_id = fpc.forum_id
LEFT JOIN forum_country_counts fcc ON fm.forum_id = fcc.forum_id
ORDER BY total_posts DESC
