/*
 Goal: Analyze sales, returns, and inventory across stores and dates, aggregating total sales, return loss, catalog return amount, and inventory levels. The query classifies inventory quantity, ranks store‑date rows, and only keeps orders that appear in both web sales and catalog returns. It demonstrates deep joins, CTE pre‑aggregation with TABLESAMPLE, a CASE expression, a window function, and set intersection.
*/
WITH inv_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        MAX(inv_date_sk) AS max_inv_date_sk
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_item_sk
),
intersected_orders AS (
    SELECT ws_order_number AS order_number
    FROM web_sales
    WHERE ws_ext_sales_price > 0
    INTERSECT
    SELECT cr_order_number AS order_number
    FROM catalog_returns
    WHERE cr_return_amount > 0
)
SELECT
    s.s_store_name,
    d.d_date,
    sm_ws.sm_type AS ship_mode_type,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(cr.cr_return_amt_inc_tax) AS total_catalog_return,
    SUM(inv.total_quantity_on_hand) AS total_inventory,
    CASE WHEN inv.total_quantity_on_hand > 500 THEN 'High' ELSE 'Low' END AS inventory_class,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY d.d_date) AS store_date_seq
FROM date_dim d
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN inv_agg inv ON ws.ws_item_sk = inv.inv_item_sk
JOIN date_dim d_inv ON inv.max_inv_date_sk = d_inv.d_date_sk
WHERE ws.ws_order_number IN (SELECT order_number FROM intersected_orders)
GROUP BY
    s.s_store_name,
    d.d_date,
    sm_ws.sm_type,
    inv.total_quantity_on_hand
HAVING SUM(ws.ws_ext_sales_price) > 0
ORDER BY total_sales DESC
LIMIT 100
