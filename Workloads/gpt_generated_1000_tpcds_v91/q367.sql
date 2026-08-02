WITH filter_items AS (
    SELECT i_item_sk, i_category, i_current_price
    FROM item
    WHERE i_current_price > 100
),
filtered_customers AS (
    SELECT c_customer_sk, c_preferred_cust_flag
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
),
store_ret_agg AS (
    SELECT i.i_category AS category,
           SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN filter_items i ON sr.sr_item_sk = i.i_item_sk
    JOIN filtered_customers c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_quantity > 0
      AND ss.ss_quantity > 0
    GROUP BY i.i_category
),
catalog_ret_agg AS (
    SELECT i.i_category AS category,
           SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN filter_items i ON cr.cr_item_sk = i.i_item_sk
    JOIN filtered_customers c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN filtered_customers c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_division_name = 'NORTH'
      AND cp.cp_department = 'DEPARTMENT'
      AND sm.sm_type = 'AIR'
      AND cr.cr_return_quantity > 0
    GROUP BY i.i_category
),
web_ret_agg AS (
    SELECT i.i_category AS category,
           SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN filter_items i ON wr.wr_item_sk = i.i_item_sk
    JOIN filtered_customers c_ref ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN filtered_customers c_ret ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'HOME'
      AND wr.wr_return_quantity > 0
    GROUP BY i.i_category
),
agg_returns AS (
    SELECT COALESCE(sr.category, cr.category, wr.category) AS category,
           COALESCE(sr.store_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0) AS total_net_loss
    FROM store_ret_agg sr
    FULL OUTER JOIN catalog_ret_agg cr ON sr.category = cr.category
    FULL OUTER JOIN web_ret_agg wr ON COALESCE(sr.category, cr.category) = wr.category
),
sales_agg AS (
    SELECT i.i_category AS category,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN filter_items i ON ss.ss_item_sk = i.i_item_sk
    JOIN filtered_customers c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_quantity > 5
      AND ss.ss_net_paid_inc_tax > 1000
    GROUP BY i.i_category
),
combined AS (
    SELECT category,
           total_net_loss AS metric,
           'RETURN' AS metric_type
    FROM agg_returns
    UNION DISTINCT
    SELECT category,
           total_net_profit AS metric,
           'SALES' AS metric_type
    FROM sales_agg
),
 dim_cc AS (
    SELECT cc.cc_call_center_sk, cc.cc_name
    FROM call_center cc
    WHERE cc.cc_division = 1
    LIMIT 5
),
 month_vals AS (
    SELECT month_num
    FROM (VALUES (1), (2), (3), (4), (5), (6)) AS t(month_num)
)
SELECT
    c.category,
    c.metric,
    c.metric_type,
    dcc.cc_name,
    mv.month_num
FROM combined c
CROSS JOIN dim_cc dcc
CROSS JOIN month_vals mv
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
    WHERE i2.i_category = c.category
      AND i2.i_current_price > 150
      AND ss.ss_quantity > 1
)
  AND c.metric > 0
ORDER BY c.metric DESC, c.category
LIMIT 100
