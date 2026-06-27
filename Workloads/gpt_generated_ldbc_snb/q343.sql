WITH friends AS (
    SELECT person1_id AS person_id, person2_id AS friend_id
    FROM person_knows_person
    UNION ALL
    SELECT person2_id AS person_id, person1_id AS friend_id
    FROM person_knows_person
),
comment_agg AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS comment_count,
           AVG(length) AS avg_comment_length
    FROM comment
    GROUP BY creator_person_id
),
work_agg AS (
    SELECT pwc.person_id,
           COUNT(DISTINCT pwc.company_id) AS distinct_company_count,
           COUNT(DISTINCT o.id) AS distinct_organisation_count,
           COUNT(DISTINCT CASE WHEN o.type = 'Company' THEN o.id END) AS company_type_count
    FROM person_work_at_company pwc
    JOIN organisation o
      ON pwc.company_id = o.id
    GROUP BY pwc.person_id
),
friend_forum_agg AS (
    SELECT f.person_id,
           COUNT(DISTINCT fm.id) AS friend_moderated_forum_count,
           COUNT(DISTINCT f.friend_id) FILTER (WHERE fm.id IS NOT NULL) AS friend_moderator_count
    FROM friends f
    JOIN person friend
      ON friend.id = f.friend_id
    LEFT JOIN forum fm
      ON fm.moderator_person_id = friend.id
    GROUP BY f.person_id
)
SELECT p.id AS person_id,
       p.first_name,
       p.last_name,
       COALESCE(ca.comment_count, 0) AS comment_count,
       COALESCE(ca.avg_comment_length, 0.0) AS avg_comment_length,
       COALESCE(wa.distinct_company_count, 0) AS distinct_company_count,
       COALESCE(wa.distinct_organisation_count, 0) AS distinct_organisation_count,
       COALESCE(wa.company_type_count, 0) AS company_type_count,
       COALESCE(ffa.friend_moderated_forum_count, 0) AS friend_moderated_forum_count,
       COALESCE(ffa.friend_moderator_count, 0) AS friend_moderator_count
FROM person p
LEFT JOIN comment_agg ca
  ON ca.person_id = p.id
LEFT JOIN work_agg wa
  ON wa.person_id = p.id
LEFT JOIN friend_forum_agg ffa
  ON ffa.person_id = p.id
ORDER BY comment_count DESC
LIMIT 10
