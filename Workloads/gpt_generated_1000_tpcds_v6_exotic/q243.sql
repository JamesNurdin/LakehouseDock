WITH
  store_sales_agg AS (
    SELECT
      s.s_store_id,
      s.s_store_name,
      d_ss.d_year,
      SUM(ss.ss_net_profit)                     AS total_net_profit,
      SUM(ss.ss_quantity)                       AS total_quantity,
      COUNT(*)                                   AS sales_txn_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d_ss.d_year = 2002
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY s.s_store_id, s.s_store_name, d_ss.d_year
  ),
  catalog_returns_agg AS (
    SELECT
      d_cr.d_year,
      SUM(cr.cr_return_amount) AS total_catalog_return,
      COUNT(*)                  AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_employees > 1500000
      AND cp.cp_type = 'PROMO'
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY d_cr.d_year
  ),
  web_returns_agg AS (
    SELECT
      d_wr.d_year,
      SUM(wr.wr_return_amt) AS total_web_return,
      COUNT(*)               AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE r2.r_reason_desc LIKE '%damage%'
    GROUP BY d_wr.d_year
  ),
  inventory_agg AS (
    SELECT
      d_inv.d_year,
      AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
      COUNT(DISTINCT inv.inv_item_sk) AS distinct_items
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    WHERE inv.inv_quantity_on_hand > 600
    GROUP BY d_inv.d_year
  )
SELECT
  ss.s_store_id,
  ss.s_store_name,
  ss.d_year,
  ss.total_net_profit,
  cr.total_catalog_return,
  wr.total_web_return,
  inv.avg_inventory_qty
FROM store_sales_agg ss
LEFT JOIN catalog_returns_agg cr ON ss.d_year = cr.d_year
LEFT JOIN web_returns_agg wr ON ss.d_year = wr.d_year
LEFT JOIN inventory_agg inv ON ss.d_year = inv.d_year
WHERE ss.total_net_profit > 100000
  AND (cr.total_catalog_return IS NULL OR cr.total_catalog_return < 50000)
  AND (wr.total_web_return IS NULL OR wr.total_web_return < 30000)
ORDER BY ss.total_net_profit DESC
LIMIT 100
