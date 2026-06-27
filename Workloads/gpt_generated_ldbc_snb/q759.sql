WITH comment_agg AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS comment_count,
           SUM(length) AS comment_total_length
    FROM comment
    GROUP BY creator_person_id
),
post_agg AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS post_count,
           SUM(length) AS post_total_length
    FROM post
    GROUP BY creator_person_id
),
comment_like_agg AS (
    SELECT person_id,
           COUNT(*) AS comment_like_count
    FROM person_likes_comment
    GROUP BY person_id
),
post_like_agg AS (
    SELECT person_id,
           COUNT(*) AS post_like_count
    FROM person_likes_post
    GROUP BY person_id
),
interest_tag_agg AS (
    SELECT person_id,
           COUNT(DISTINCT tag_id) AS interest_tag_count
    FROM person_has_interest_tag
    GROUP BY person_id
),
friend_agg AS (
    SELECT person1_id AS person_id,
           COUNT(DISTINCT person2_id) AS friend_count
    FROM person_knows_person
    GROUP BY person1_id
),
work_agg AS (
    SELECT person_id,
           COUNT(DISTINCT company_id) AS work_company_count
    FROM person_work_at_company
    GROUP BY person_id
),
study_agg AS (
    SELECT person_id,
           COUNT(DISTINCT university_id) AS study_university_count
    FROM person_study_at_university
    GROUP BY person_id
)
SELECT p.id AS person_id,
       p.first_name,
       p.last_name,
       p.gender,
       pl.name AS city_name,
       COALESCE(ca.comment_count, 0) AS comment_count,
       COALESCE(ca.comment_total_length, 0) AS comment_total_length,
       COALESCE(pa.post_count, 0) AS post_count,
       COALESCE(pa.post_total_length, 0) AS post_total_length,
       COALESCE(cl.comment_like_count, 0) AS comment_like_count,
       COALESCE(plike.post_like_count, 0) AS post_like_count,
       COALESCE(it.interest_tag_count, 0) AS interest_tag_count,
       COALESCE(fr.friend_count, 0) AS friend_count,
       COALESCE(wk.work_company_count, 0) AS work_company_count,
       COALESCE(st.study_university_count, 0) AS study_university_count,
       (COALESCE(ca.comment_count, 0) + COALESCE(pa.post_count, 0) +
        COALESCE(cl.comment_like_count, 0) + COALESCE(plike.post_like_count, 0) +
        COALESCE(fr.friend_count, 0) + COALESCE(wk.work_company_count, 0) +
        COALESCE(st.study_university_count, 0)) AS activity_score
FROM person p
LEFT JOIN place pl
  ON p.location_city_id = pl.id
LEFT JOIN comment_agg ca
  ON p.id = ca.person_id
LEFT JOIN post_agg pa
  ON p.id = pa.person_id
LEFT JOIN comment_like_agg cl
  ON p.id = cl.person_id
LEFT JOIN post_like_agg plike
  ON p.id = plike.person_id
LEFT JOIN interest_tag_agg it
  ON p.id = it.person_id
LEFT JOIN friend_agg fr
  ON p.id = fr.person_id
LEFT JOIN work_agg wk
  ON p.id = wk.person_id
LEFT JOIN study_agg st
  ON p.id = st.person_id
ORDER BY activity_score DESC
LIMIT 10
