WITH store_agg AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_state AS state,
    cd.cd_gender,
    hd.hd_income_band_sk,
    p.p_promo_id,
    w.w_warehouse_id,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_qty,
    CASE
      WHEN SUM(ss.ss_net_paid_inc_tax) > (
        SELECT AVG(ss2.ss_net_paid_inc_tax)
        FROM store_sales ss2
      ) THEN 'High'
      ELSE 'Low'
    END AS sales_level
  FROM store_sales ss
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  LEFT JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  WHERE s.s_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
    AND cd.cd_purchase_estimate >= 2000
    AND hd.hd_income_band_sk = 3
    AND inv.inv_quantity_on_hand > 500
    AND p.p_discount_active = 'Y'
  GROUP BY
    s.s_store_id,
    s.s_state,
    cd.cd_gender,
    hd.hd_income_band_sk,
    p.p_promo_id,
    w.w_warehouse_id
)
SELECT
  store_id,
  state,
  sales_level,
  total_sales,
  total_profit,
  total_quantity,
  total_return_qty,
  (total_sales / NULLIF(num_transactions, 0)) AS avg_sales_per_txn,
  CASE
    WHEN total_profit > 10000 THEN 'Big'
    ELSE 'Small'
  END AS profit_category
FROM store_agg
WHERE total_sales > (SELECT AVG(total_sales) FROM store_agg)
ORDER BY total_sales DESC
LIMIT 100
