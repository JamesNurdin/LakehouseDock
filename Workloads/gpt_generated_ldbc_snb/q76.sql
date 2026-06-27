WITH liked_comments_agg AS (
      SELECT person_id,
             COUNT(DISTINCT comment_id) AS liked_comments_count
      FROM person_likes_comment
      GROUP BY person_id
   ),
   authored_comments_agg AS (
      SELECT creator_person_id AS person_id,
             COUNT(*) AS authored_comments_count,
             AVG(length) AS avg_comment_length
      FROM comment
      GROUP BY creator_person_id
   ),
   authored_posts_agg AS (
      SELECT creator_person_id AS person_id,
             COUNT(*) AS authored_posts_count
      FROM post
      GROUP BY creator_person_id
   ),
   friends_agg AS (
      SELECT person_id,
             COUNT(DISTINCT friend_id) AS friend_count
      FROM (
            SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
            UNION ALL
            SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
           ) f
      GROUP BY person_id
   ),
   interest_tags_agg AS (
      SELECT person_id,
             COUNT(DISTINCT tag_id) AS interest_tags_count
      FROM person_has_interest_tag
      GROUP BY person_id
   ),
   forum_members_agg AS (
      SELECT person_id,
             COUNT(DISTINCT forum_id) AS forum_membership_count
      FROM forum_has_member_person
      GROUP BY person_id
   ),
   work_agg AS (
      SELECT person_id,
             COUNT(DISTINCT company_id) AS companies_worked_at_count
      FROM person_work_at_company
      GROUP BY person_id
   ),
   study_agg AS (
      SELECT person_id,
             COUNT(DISTINCT university_id) AS universities_studied_at_count
      FROM person_study_at_university
      GROUP BY person_id
   )
SELECT
   per.id,
   per.first_name,
   per.last_name,
   COALESCE(lc.liked_comments_count, 0)           AS liked_comments_count,
   COALESCE(ac.authored_comments_count, 0)       AS authored_comments_count,
   ac.avg_comment_length,
   COALESCE(ap.authored_posts_count, 0)          AS authored_posts_count,
   COALESCE(f.friend_count, 0)                   AS friend_count,
   COALESCE(it.interest_tags_count, 0)           AS interest_tags_count,
   COALESCE(fm.forum_membership_count, 0)        AS forum_membership_count,
   COALESCE(w.companies_worked_at_count, 0)      AS companies_worked_at_count,
   COALESCE(s.universities_studied_at_count, 0)  AS universities_studied_at_count
FROM person per
LEFT JOIN liked_comments_agg lc   ON lc.person_id = per.id
LEFT JOIN authored_comments_agg ac ON ac.person_id = per.id
LEFT JOIN authored_posts_agg ap    ON ap.person_id = per.id
LEFT JOIN friends_agg f            ON f.person_id = per.id
LEFT JOIN interest_tags_agg it    ON it.person_id = per.id
LEFT JOIN forum_members_agg fm    ON fm.person_id = per.id
LEFT JOIN work_agg w              ON w.person_id = per.id
LEFT JOIN study_agg s             ON s.person_id = per.id
ORDER BY per.id
