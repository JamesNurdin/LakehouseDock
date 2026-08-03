WITH
  agg_returns AS (
    SELECT
      d.d_year,
      cd.cd_gender,
      SUM(cr.cr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY GROUPING SETS (
      (d.d_year, cd.cd_gender),
      (d.d_year),
      (cd.cd_gender)
    )
  ),
  agg_sales AS (
    SELECT
      d.d_year,
      cd.cd_gender,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(*) AS sale_cnt
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY GROUPING SETS (
      (d.d_year, cd.cd_gender),
      (d.d_year),
      (cd.cd_gender)
    )
  ),
  full_agg AS (
    SELECT
      COALESCE(r.d_year, s.d_year) AS year,
      COALESCE(r.cd_gender, s.cd_gender) AS gender,
      r.total_net_loss,
      s.total_profit
    FROM agg_returns r
    FULL OUTER JOIN agg_sales s
      ON r.d_year = s.d_year
     AND r.cd_gender = s.cd_gender
  ),
  intersect_keys AS (
    SELECT cr.cr_order_number AS order_key
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_ticket_number AS order_key
    FROM store_returns sr
  ),
  intersected_orders AS (
    SELECT order_key
    FROM intersect_keys
    INTERSECT
    SELECT order_key FROM intersect_keys
  ),
  warehouse_returns AS (
    SELECT
      w.w_warehouse_name AS warehouse,
      SUM(cr.cr_net_loss) AS warehouse_loss
    FROM catalog_returns cr
    RIGHT OUTER JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_order_number IN (SELECT order_key FROM intersected_orders)
    GROUP BY w.w_warehouse_name
  )
SELECT
  year,
  gender,
  total_net_loss,
  total_profit,
  NULL AS warehouse,
  NULL AS warehouse_loss
FROM full_agg
UNION
SELECT
  NULL AS year,
  NULL AS gender,
  NULL AS total_net_loss,
  NULL AS total_profit,
  warehouse,
  warehouse_loss
FROM warehouse_returns
ORDER BY year DESC NULLS LAST, warehouse
LIMIT 100
