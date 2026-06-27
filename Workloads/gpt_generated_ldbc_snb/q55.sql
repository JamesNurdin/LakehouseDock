WITH forum_posts AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           f.moderator_person_id,
           COUNT(p.id) AS total_posts,
           AVG(p.length) AS avg_post_length,
           COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id, f.title, f.moderator_person_id
),
forum_members AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fmp.person_id) AS total_members
    FROM forum f
    JOIN forum_has_member_person fmp
        ON fmp.forum_id = f.id
    GROUP BY f.id
),
forum_members_friends AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p1.id) AS members_with_friends
    FROM forum f
    JOIN forum_has_member_person fmp1
        ON fmp1.forum_id = f.id
    JOIN person p1
        ON p1.id = fmp1.person_id
    JOIN person_knows_person kp
        ON kp.person1_id = p1.id
    JOIN person p2
        ON p2.id = kp.person2_id
    JOIN forum_has_member_person fmp2
        ON fmp2.forum_id = f.id
        AND fmp2.person_id = p2.id
    GROUP BY f.id
),
forum_member_companies AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT org.id) AS distinct_member_companies
    FROM forum f
    JOIN forum_has_member_person fmp
        ON fmp.forum_id = f.id
    JOIN person p
        ON p.id = fmp.person_id
    JOIN person_work_at_company pwc
        ON pwc.person_id = p.id
    JOIN organisation org
        ON org.id = pwc.company_id
    GROUP BY f.id
),
moderators AS (
    SELECT p.id AS moderator_id,
           p.first_name,
           p.last_name
    FROM person p
)
SELECT fp.forum_id,
       fp.forum_title,
       fp.total_posts,
       fp.avg_post_length,
       fp.distinct_post_creators,
       fm.total_members,
       COALESCE(fmf.members_with_friends, 0) AS members_with_friends,
       COALESCE(fmc.distinct_member_companies, 0) AS distinct_member_companies,
       m.first_name AS moderator_first_name,
       m.last_name AS moderator_last_name
FROM forum_posts fp
JOIN forum_members fm
    ON fm.forum_id = fp.forum_id
LEFT JOIN forum_members_friends fmf
    ON fmf.forum_id = fp.forum_id
LEFT JOIN forum_member_companies fmc
    ON fmc.forum_id = fp.forum_id
LEFT JOIN moderators m
    ON m.moderator_id = fp.moderator_person_id
ORDER BY fp.total_posts DESC
LIMIT 10
