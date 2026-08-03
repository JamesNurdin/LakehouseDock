WITH
  cte_catalog_keys AS (
    SELECT cs.cs_item_sk AS item_sk,
           cs.cs_order_number AS order_number
    FROM catalog_sales cs
  ),
  cte_store_keys AS (
    SELECT ss.ss_item_sk AS item_sk,
           ss.ss_ticket_number AS order_number
    FROM store_sales ss
  ),
  cte_web_keys AS (
    SELECT ws.ws_item_sk AS item_sk,
           ws.ws_order_number AS order_number
    FROM web_sales ws
  ),
  except_catalog_not_store AS (
    SELECT item_sk, order_number FROM cte_catalog_keys
    EXCEPT
    SELECT item_sk, order_number FROM cte_store_keys
  ),
  intersect_catalog_web AS (
    SELECT item_sk, order_number FROM cte_catalog_keys
    INTERSECT
    SELECT item_sk, order_number FROM cte_web_keys
  ),
  full_returns AS (
    SELECT *
    FROM catalog_returns cr
    FULL OUTER JOIN store_returns sr
      ON cr.cr_item_sk = sr.sr_item_sk
     AND cr.cr_order_number = sr.sr_ticket_number
  )
SELECT
  d.d_year,
  cd.cd_gender,
  sm.sm_type,
  SUM(cs.cs_net_paid) AS catalog_net_paid,
  SUM(ss.ss_net_paid) AS store_net_paid,
  SUM(ws.ws_net_paid) AS web_net_paid,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
  COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
  COUNT(DISTINCT ws.ws_order_number) AS web_orders,
  COUNT(*) FILTER (WHERE cr.cr_order_number IS NOT NULL) AS catalog_returns,
  COUNT(*) FILTER (WHERE sr.sr_ticket_number IS NOT NULL) AS store_returns,
  COUNT(*) FILTER (WHERE wr.wr_order_number IS NOT NULL) AS web_returns,
  (SELECT COUNT(*) FROM except_catalog_not_store) AS catalog_not_in_store_cnt,
  (SELECT COUNT(*) FROM intersect_catalog_web) AS catalog_web_intersect_cnt,
  (SELECT COUNT(*) FROM full_returns) AS full_return_rows
FROM
  date_dim d
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk AND cr.cr_order_number = cs.cs_order_number
  LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
WHERE
  d.d_year BETWEEN 1999 AND 2001
  AND cd.cd_gender = 'F'
  AND sm.sm_type = 'AIR'
GROUP BY
  d.d_year,
  cd.cd_gender,
  sm.sm_type
HAVING
  SUM(cs.cs_net_paid) > 100000
ORDER BY
  d.d_year DESC,
  catalog_net_paid DESC
LIMIT 100
