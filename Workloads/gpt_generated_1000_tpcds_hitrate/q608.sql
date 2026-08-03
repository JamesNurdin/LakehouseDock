WITH
  high_spend AS (
    SELECT ws.ws_bill_customer_sk AS customer_sk,
           SUM(ws.ws_net_paid) AS total_spent
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451400 AND 2451500
    GROUP BY ws.ws_bill_customer_sk
    HAVING SUM(ws.ws_net_paid) > 10000
  ),
  low_spend AS (
    SELECT sr.sr_customer_sk AS customer_sk,
           -SUM(sr.sr_return_amt) AS total_spent
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451400 AND 2451500
    GROUP BY sr.sr_customer_sk
    HAVING SUM(sr.sr_return_amt) < 1000
  ),
  ship_modes AS (
    SELECT sm_ship_mode_sk, sm_ship_mode_id
    FROM ship_mode
    WHERE sm_ship_mode_id IN ('SM1', 'SM2')
  ),
  years AS (
    SELECT 2020 AS year UNION ALL SELECT 2021 AS year
  ),
  combined_high AS (
    SELECT h.customer_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           h.total_spent,
           CASE WHEN h.total_spent > 20000 THEN 'Platinum' ELSE 'Gold' END AS tier,
           sm.sm_ship_mode_id,
           y.year
    FROM high_spend h
    JOIN customer c ON h.customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN ship_modes sm
    CROSS JOIN years y
    WHERE h.customer_sk IN (
      SELECT customer_sk FROM high_spend
      EXCEPT
      SELECT customer_sk FROM low_spend
    )
  ),
  combined_low AS (
    SELECT l.customer_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           l.total_spent,
           CASE WHEN l.total_spent < 0 THEN 'Returner' ELSE 'Other' END AS tier,
           sm.sm_ship_mode_id,
           y.year
    FROM low_spend l
    JOIN customer c ON l.customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN ship_modes sm
    CROSS JOIN years y
  )
SELECT
  u.customer_sk,
  u.cd_gender,
  u.cd_marital_status,
  u.tier,
  u.sm_ship_mode_id,
  u.year,
  SUM(u.total_spent) AS sum_spent,
  COUNT(*) AS cnt,
  (SELECT COUNT(*) FROM store_returns sr3 WHERE sr3.sr_customer_sk = u.customer_sk) AS return_cnt
FROM (
  SELECT * FROM combined_high
  UNION ALL
  SELECT * FROM combined_low
) u
GROUP BY GROUPING SETS (
  (u.customer_sk, u.tier, u.sm_ship_mode_id, u.year),
  (u.cd_gender, u.cd_marital_status, u.tier),
  (u.year)
)
ORDER BY sum_spent DESC
LIMIT 100
