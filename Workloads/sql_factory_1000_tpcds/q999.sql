WITH review_info AS (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_credit_rating,
    dr.d_date AS last_review_date,
    DATE_DIFF('day', dr.d_date, CURRENT_DATE) AS days_since_review,
    CASE
      WHEN DATE_DIFF('day', dr.d_date, CURRENT_DATE) <= 180 THEN 'Active'
      ELSE 'Inactive'
    END AS activity_status
  FROM customer c
  JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN date_dim dr ON c.c_last_review_date = dr.d_date_sk
)
SELECT
  c_customer_id,
  c_first_name,
  c_last_name,
  cd_gender,
  cd_credit_rating,
  last_review_date,
  days_since_review,
  activity_status,
  AVG(days_since_review) OVER (PARTITION BY cd_gender) AS avg_days_since_review_by_gender,
  RANK() OVER (PARTITION BY cd_gender ORDER BY days_since_review ASC) AS recent_review_rank
FROM review_info
WHERE activity_status = 'Active'
ORDER BY cd_gender, recent_review_rank
