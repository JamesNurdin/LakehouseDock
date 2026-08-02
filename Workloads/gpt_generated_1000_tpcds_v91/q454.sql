WITH
sales_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_customer_sk,
        ss_hdemo_sk,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales_amount
    FROM store_sales
    GROUP BY ss_item_sk, ss_sold_date_sk, ss_sold_time_sk, ss_customer_sk, ss_hdemo_sk
),
inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk, inv_date_sk
)
SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    w.w_warehouse_name,
    SUM(sa.total_sales_amount) AS sum_sales_amount,
    SUM(sa.total_quantity) AS sum_quantity,
    SUM(sa.total_net_profit) AS sum_net_profit,
    CASE WHEN SUM(sa.total_net_profit) > 0 THEN 'Profitable' ELSE 'Not Profitable' END AS profit_flag,
    RANK() OVER (ORDER BY SUM(sa.total_net_profit) DESC) AS profit_rank
FROM sales_agg sa
JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t_sales ON sa.ss_sold_time_sk = t_sales.t_time_sk
JOIN item i ON sa.ss_item_sk = i.i_item_sk
JOIN customer c ON sa.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON sa.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory_agg inv ON i.i_item_sk = inv.inv_item_sk AND d.d_date_sk = inv.inv_date_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
  AND i.i_current_price > 100
  AND w.w_state = 'CA'
  AND ib.ib_lower_bound >= 50000
  AND cc.cc_name LIKE 'Call%'
  AND t_sales.t_hour BETWEEN 9 AND 17
GROUP BY ROLLUP (d.d_year, i.i_category, i.i_brand, w.w_warehouse_name)
ORDER BY d.d_year, i.i_category, i.i_brand, w.w_warehouse_name
LIMIT 100
