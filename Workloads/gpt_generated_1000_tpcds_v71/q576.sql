WITH agg AS (
    SELECT
        ca.ca_state,
        cd.cd_gender,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        SUM(ss.ss_net_paid + ws.ws_net_paid - cr.cr_return_amount) AS net_revenue
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN item i1 ON ss.ss_item_sk = i1.i_item_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN time_dim t3 ON wr.wr_returned_time_sk = t3.t_time_sk
    JOIN item i3 ON wr.wr_item_sk = i3.i_item_sk
    JOIN web_page wp2 ON wr.wr_web_page_sk = wp2.wp_web_page_sk
    JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN time_dim t4 ON cr.cr_returned_time_sk = t4.t_time_sk
    JOIN item i4 ON cr.cr_item_sk = i4.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE ca.ca_country = 'United States'
      AND i1.i_current_price > 100
      AND t1.t_hour BETWEEN 9 AND 17
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_upper_bound <= 120000
    GROUP BY ROLLUP (ca.ca_state, cd.cd_gender)
    HAVING SUM(ss.ss_net_paid + ws.ws_net_paid - cr.cr_return_amount) > 50000
)
SELECT
    ca_state,
    cd_gender,
    total_store_sales,
    total_web_sales,
    total_catalog_returns,
    distinct_customers,
    net_revenue,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY net_revenue DESC) AS state_rank
FROM agg
ORDER BY ca_state NULLS LAST, cd_gender NULLS LAST, net_revenue DESC
LIMIT 100
