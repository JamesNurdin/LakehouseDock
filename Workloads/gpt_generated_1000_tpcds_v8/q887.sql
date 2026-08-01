WITH
  agg_returns AS (
    SELECT
      wr_reason_sk,
      SUM(wr_return_amt)               AS total_return_amt,
      COUNT(*)                         AS return_cnt,
      MIN(wr_returned_date_sk)         AS min_return_date_sk
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_return_amt      > 0
      AND wr_fee             < 100
      AND wr_return_tax      >= 0
      AND wr_return_ship_cost>= 0
    GROUP BY wr_reason_sk
  ),
  full_reason AS (
    SELECT
      ar.wr_reason_sk,
      ar.total_return_amt,
      ar.return_cnt,
      r.r_reason_desc,
      r.r_reason_id
    FROM agg_returns ar
    FULL OUTER JOIN reason r
      ON ar.wr_reason_sk = r.r_reason_sk
  ),
  union_returns AS (
    SELECT
      fr.wr_reason_sk,
      fr.r_reason_desc,
      fr.total_return_amt,
      fr.return_cnt
    FROM full_reason fr
    UNION DISTINCT
    SELECT
      r.r_reason_sk,
      r.r_reason_desc,
      0.0 AS total_return_amt,
      0   AS return_cnt
    FROM reason r
    WHERE NOT EXISTS (
            SELECT 1 FROM agg_returns ar2 WHERE ar2.wr_reason_sk = r.r_reason_sk
          )
  )
SELECT
  ur.r_reason_desc,
  ur.total_return_amt,
  ur.return_cnt,
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END                     AS gender_label,
  CASE WHEN cd.cd_marital_status = 'M' THEN 'Married' ELSE 'Single' END        AS marital_status_desc,
  wp.wp_url,
  td.t_hour,
  mp.meal_period,
  ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY ur.total_return_amt DESC) AS rn_gender,
  SUM(ur.total_return_amt) OVER (PARTITION BY ur.r_reason_desc)                AS sum_by_reason
FROM union_returns ur
JOIN web_returns wr
  ON ur.wr_reason_sk = wr.wr_reason_sk
JOIN time_dim td
  ON wr.wr_returned_time_sk = td.t_time_sk
CROSS JOIN LATERAL (
      SELECT CASE WHEN td.t_hour BETWEEN 12 AND 13 THEN 'Lunch' ELSE 'Other' END AS meal_period
) AS mp
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer c
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2 AS dummy) AS d
WHERE ur.r_reason_desc LIKE '%purchase%'
  AND wp.wp_link_count      > 10
  AND wp.wp_max_ad_count    <= 3
  AND td.t_hour              BETWEEN 9 AND 17
  AND c.c_birth_year        BETWEEN 1970 AND 1990
  AND cd.cd_credit_rating    = 'A'
  AND NOT EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_web_page_sk = wr.wr_web_page_sk
          AND wp2.wp_image_count > 5
      )
ORDER BY ur.total_return_amt DESC
LIMIT 100
