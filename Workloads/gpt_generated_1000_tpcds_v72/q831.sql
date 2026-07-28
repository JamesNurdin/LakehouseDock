WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001
    )
    GROUP BY inv_item_sk
)
SELECT DISTINCT
       cs.cs_order_number,
       i.i_item_id,
       i.i_category,
       s.s_store_name,
       cs.cs_net_profit,
       CASE WHEN cr.cr_return_amount > 0 THEN 'Returned' ELSE 'Sold' END AS sale_status,
       ib.ib_upper_bound,
       sm.sm_type,
       inv_agg.total_qty_on_hand,
       (
           SELECT AVG(cr2.cr_return_amount)
           FROM catalog_returns cr2
           WHERE cr2.cr_item_sk = i.i_item_sk
       ) AS avg_item_return_amount,
       RANK() OVER (PARTITION BY s.s_store_name ORDER BY cs.cs_net_profit DESC) AS profit_rank
FROM catalog_sales cs
JOIN date_dim sd_sold
  ON cs.cs_sold_date_sk = sd_sold.d_date_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN store s
  ON s.s_closed_date_sk = sd_sold.d_date_sk
JOIN inv_agg
  ON i.i_item_sk = inv_agg.inv_item_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim dr_return
  ON cr.cr_returned_date_sk = dr_return.d_date_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim dr_wr
  ON wr.wr_returned_date_sk = dr_wr.d_date_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim dr_wp_creation
  ON wp.wp_creation_date_sk = dr_wp_creation.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = dr_wp_creation.d_date_sk
WHERE sd_sold.d_year = 2001
  AND sd_sold.d_month_seq BETWEEN 200101 AND 200112
  AND ib.ib_upper_bound >= 100000
  AND sm.sm_type = 'AIR'
  AND cr.cr_return_amount > 100.0
ORDER BY profit_rank
LIMIT 100
