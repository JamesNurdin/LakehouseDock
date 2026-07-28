WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        ss.ss_net_profit,
        CASE WHEN ss.ss_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_level,
        cc.cc_state,
        cp.cp_catalog_page_id,
        w.w_warehouse_name,
        wp.wp_web_page_id,
        cr.cr_return_quantity,
        wr.wr_return_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_class_id IN (10, 14)
      AND p.p_discount_active = 'N'
      AND c.c_preferred_cust_flag = 'Y'
      AND cc.cc_state = 'CA'
      AND hd.hd_vehicle_count > 1
)
SELECT
    d_year,
    i_category,
    SUM(ss_net_profit) AS total_net_profit,
    CASE WHEN SUM(ss_net_profit) > 5000 THEN 'Very High' ELSE 'Normal' END AS profit_bucket,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
FROM base
GROUP BY ROLLUP (d_year, i_category)
ORDER BY d_year, i_category
LIMIT 100
