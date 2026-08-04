/*
Goal: Produce a deep‑join analytical view that correlates web sales with catalog returns, dimensions, promotions and warehouses, while demonstrating set operations (INTERSECT, EXCEPT), a scalar subquery, row numbering and table sampling. The result is grouped by web site and sales date, ordered by total net paid, and limited to the top 100 rows.
*/
WITH
  /* Sample a fraction of warehouses to illustrate TABLESAMPLE */
  sampled_warehouse AS (
    SELECT *
    FROM warehouse TABLESAMPLE BERNOULLI (10)
  ),
  /* Orders that appear in both sales and returns */
  intersect_orders AS (
    SELECT ws_order_number
    FROM web_sales
    INTERSECT
    SELECT cr_order_number
    FROM catalog_returns
  ),
  /* Orders that appear in sales but not in returns */
  except_orders AS (
    SELECT ws_order_number
    FROM web_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
  )
SELECT
  ws.ws_web_site_sk,
  ws_site.web_name,
  ws.ws_sold_date_sk,
  SUM(ws.ws_net_paid)                     AS total_net_paid,
  COUNT(DISTINCT ws.ws_order_number)      AS total_orders,
  COUNT(DISTINCT cr.cr_order_number)      AS total_returns,
  ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS rn,
  /* Scalar sub‑query */
  (SELECT COUNT(*) FROM catalog_returns WHERE cr_return_amount > 100) AS high_return_cnt
FROM web_sales ws
  /* Core sales dimension joins */
  INNER JOIN item i1               ON ws.ws_item_sk      = i1.i_item_sk
  INNER JOIN promotion p           ON ws.ws_promo_sk     = p.p_promo_sk
  INNER JOIN item i2               ON p.p_item_sk        = i2.i_item_sk
  INNER JOIN customer_demographics cd_bill      ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  INNER JOIN household_demographics hd_bill      ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  INNER JOIN income_band ib        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  INNER JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  INNER JOIN ship_mode sm_ship    ON ws.ws_ship_mode_sk = sm_ship.sm_ship_mode_sk
  INNER JOIN sampled_warehouse w_samp ON ws.ws_warehouse_sk = w_samp.w_warehouse_sk
  INNER JOIN web_page wp          ON ws.ws_web_page_sk  = wp.wp_web_page_sk
  INNER JOIN web_site ws_site     ON ws.ws_web_site_sk  = ws_site.web_site_sk
  /* Join to catalog returns – left side to keep sales without a return */
  LEFT JOIN catalog_returns cr     ON ws.ws_order_number = cr.cr_order_number
  LEFT JOIN item i3                ON cr.cr_item_sk       = i3.i_item_sk
  LEFT JOIN call_center cc        ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN catalog_page cp       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN ship_mode sm_ret      ON cr.cr_ship_mode_sk   = sm_ret.sm_ship_mode_sk
  LEFT JOIN sampled_warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
  LEFT JOIN customer_demographics cd_returning   ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
  LEFT JOIN customer_demographics cd_refunded    ON cr.cr_refunded_cdemo_sk  = cd_refunded.cd_demo_sk
  LEFT JOIN household_demographics hd_returning  ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
  LEFT JOIN household_demographics hd_refunded   ON cr.cr_refunded_hdemo_sk  = hd_refunded.hd_demo_sk
  LEFT JOIN customer_address ca_returning        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
  LEFT JOIN customer_address ca_refunded         ON cr.cr_refunded_addr_sk  = ca_refunded.ca_address_sk
WHERE ws.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
  AND ws.ws_order_number NOT IN (SELECT ws_order_number FROM except_orders)
  /* Example surrogate‑key date range filter */
  AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451170
GROUP BY ws.ws_web_site_sk,
         ws_site.web_name,
         ws.ws_sold_date_sk
ORDER BY total_net_paid DESC
LIMIT 100
