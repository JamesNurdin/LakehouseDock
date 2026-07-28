WITH
  sales_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(ws.ws_net_paid) AS total_sales,
      COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND i.i_units = 'Each'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
    GROUP BY d.d_year, i.i_category
  ),
  returns_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(sr.sr_net_loss) AS total_loss,
      COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND i.i_units = 'Each'
      AND r.r_reason_desc LIKE '%Defect%'
      AND s.s_state = 'CA'
    GROUP BY d.d_year, i.i_category
  ),
  web_returns_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(wr.wr_net_loss) AS web_return_loss,
      COUNT(*) AS web_returns_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c_refund ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer_demographics cd_refund ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN household_demographics hd_refund ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND i.i_units = 'Each'
      AND r.r_reason_desc LIKE '%Late%'
    GROUP BY d.d_year, i.i_category
  ),
  call_center_agg AS (
    SELECT
      d.d_year,
      cc.cc_name,
      COUNT(*) AS call_cnt
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cc.cc_state = 'CA'
      AND cc.cc_gmt_offset >= -5
    GROUP BY d.d_year, cc.cc_name
  )
SELECT
  combined.d_year,
  combined.category,
  SUM(combined.amount) AS net_amount,
  COALESCE(SUM(wr.web_return_loss), 0) AS web_return_loss,
  COUNT(*) AS rows_in_result
FROM (
  SELECT d_year, i_category AS category, total_sales AS amount
  FROM sales_agg
  UNION ALL
  SELECT d_year, i_category AS category, -total_loss AS amount
  FROM returns_agg
) combined
LEFT JOIN web_returns_agg wr
  ON combined.d_year = wr.d_year
  AND combined.category = wr.i_category
JOIN call_center_agg cca
  ON combined.d_year = cca.d_year
WHERE combined.amount <> 0
GROUP BY combined.d_year, combined.category
HAVING SUM(combined.amount) > 10000
ORDER BY net_amount DESC
LIMIT 100
