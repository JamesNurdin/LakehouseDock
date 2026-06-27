WITH forum_mod AS (
    SELECT f.id AS forum_id,
           f.title,
           f.creation_date AS forum_creation_date,
           f.moderator_person_id,
           p.first_name AS moderator_first_name,
           p.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person p
        ON f.moderator_person_id = p.id
),
member_counts AS (
    SELECT fhmp.forum_id,
           COUNT(DISTINCT fhmp.person_id) AS member_count
    FROM forum_has_member_person fhmp
    GROUP BY fhmp.forum_id
),
post_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
tag_counts AS (
    SELECT fht.forum_id,
           COUNT(DISTINCT fht.tag_id) AS tag_count
    FROM forum_has_tag_tag fht
    GROUP BY fht.forum_id
),
member_friend_counts AS (
    SELECT fhmp.forum_id,
           fhmp.person_id AS member_id,
           COUNT(DISTINCT pkp.person2_id) AS friend_count
    FROM forum_has_member_person fhmp
    JOIN person p
        ON fhmp.person_id = p.id
    LEFT JOIN person_knows_person pkp
        ON p.id = pkp.person1_id
    GROUP BY fhmp.forum_id, fhmp.person_id
),
avg_friends_per_forum AS (
    SELECT forum_id,
           AVG(friend_count) AS avg_friends_per_member
    FROM member_friend_counts
    GROUP BY forum_id
),
member_university_counts AS (
    SELECT fhmp.forum_id,
           COUNT(DISTINCT psu.person_id) AS member_university_count
    FROM forum_has_member_person fhmp
    JOIN person p
        ON fhmp.person_id = p.id
    LEFT JOIN person_study_at_university psu
        ON p.id = psu.person_id
    GROUP BY fhmp.forum_id
)
SELECT fm.forum_id,
       fm.title,
       fm.forum_creation_date,
       fm.moderator_first_name,
       fm.moderator_last_name,
       COALESCE(mc.member_count, 0) AS member_count,
       COALESCE(ps.post_count, 0) AS post_count,
       COALESCE(ps.avg_post_length, 0) AS avg_post_length,
       COALESCE(tc.tag_count, 0) AS tag_count,
       COALESCE(af.avg_friends_per_member, 0) AS avg_friends_per_member,
       COALESCE(muc.member_university_count, 0) AS member_university_count
FROM forum_mod fm
LEFT JOIN member_counts mc
    ON fm.forum_id = mc.forum_id
LEFT JOIN post_stats ps
    ON fm.forum_id = ps.forum_id
LEFT JOIN tag_counts tc
    ON fm.forum_id = tc.forum_id
LEFT JOIN avg_friends_per_forum af
    ON fm.forum_id = af.forum_id
LEFT JOIN member_university_counts muc
    ON fm.forum_id = muc.forum_id
ORDER BY member_count DESC
LIMIT 10
