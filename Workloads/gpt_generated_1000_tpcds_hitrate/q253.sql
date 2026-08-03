WITH ws_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_sold_date_sk,
        ws_web_page_sk,
        ws_web_site_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(*) AS ws_order_cnt,
        MIN(ws_order_number) AS sample_ws_order_number
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451000 AND 2452000
      AND ws_ext_wholesale_cost > 500
    GROUP BY ws_warehouse_sk, ws_sold_date_sk, ws_web_page_sk, ws_web_site_sk
)
SELECT
    w.w_warehouse_name,
    t.t_hour,
    web_site.web_name,
    SUM(ws_agg.total_net_paid) AS sum_total_net_paid,
    COUNT(DISTINCT cr.cr_item_sk) AS distinct_returned_items,
    SUM(CASE WHEN ib.ib_lower_bound >= 50000 THEN cr.cr_net_loss ELSE 0 END) AS high_income_net_loss,
    AVG(ws_agg.ws_order_cnt) AS avg_orders_per_warehouse
FROM catalog_returns cr
FULL OUTER JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
LEFT JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN income_band ib
    ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
LEFT JOIN ws_agg
    ON w.w_warehouse_sk = ws_agg.ws_warehouse_sk
LEFT JOIN web_page wp
    ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site
    ON ws_agg.ws_web_site_sk = web_site.web_site_sk
WHERE w.w_state IN ('TN', 'PA', 'LA')
  AND ib.ib_upper_bound <= 100000
  AND t.t_hour BETWEEN 8 AND 17
  AND web_site.web_market_manager = 'John Doe'
  AND cr.cr_order_number IN (
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_ext_ship_cost > 1000
    )
GROUP BY w.w_warehouse_name, t.t_hour, web_site.web_name
ORDER BY high_income_net_loss DESC, distinct_returned_items DESC
LIMIT 100
