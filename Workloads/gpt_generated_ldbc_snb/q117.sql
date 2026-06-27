WITH member_details AS (
    SELECT fhm.forum_id,
           fhm.person_id
    FROM forum_has_member_person fhm
    JOIN person p
      ON fhm.person_id = p.id
),
friend_counts AS (
    SELECT person_id,
           COUNT(*) AS friend_count
    FROM (
        SELECT person1_id AS person_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id FROM person_knows_person
    ) pk
    GROUP BY person_id
),
company_counts AS (
    SELECT person_id,
           COUNT(DISTINCT company_id) AS distinct_company_count,
           AVG(work_from) AS avg_work_from
    FROM person_work_at_company
    GROUP BY person_id
)
SELECT md.forum_id,
       COUNT(DISTINCT md.person_id) AS member_count,
       AVG(COALESCE(fc.friend_count, 0)) AS avg_friends_per_member,
       AVG(COALESCE(cc.distinct_company_count, 0)) AS avg_distinct_companies_per_member,
       AVG(COALESCE(cc.avg_work_from, 0)) AS avg_work_start_year_per_member
FROM member_details md
LEFT JOIN friend_counts fc
  ON md.person_id = fc.person_id
LEFT JOIN company_counts cc
  ON md.person_id = cc.person_id
GROUP BY md.forum_id
ORDER BY member_count DESC
LIMIT 10
