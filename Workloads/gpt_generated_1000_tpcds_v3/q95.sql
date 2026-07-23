WITH per_ship_year AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        sm.sm_type AS ship_type,
        d_ss.d_year AS year,
        SUM(ss.ss_net_profit) AS store_net_profit_sum,
        SUM(cs.cs_net_profit) AS catalog_net_profit_sum,
        SUM(ws.ws_net_profit) AS web_net_profit_sum,
        SUM(ss.ss_ext_sales_price) AS store_sales_sum,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_sum,
        SUM(ws.ws_ext_sales_price) AS web_sales_sum,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        COUNT(*) AS transaction_cnt
    FROM
        store_sales ss
        JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
        JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_hdemo_sk = hd.hd_demo_sk
            AND sr.sr_addr_sk = ca.ca_address_sk
        LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
        JOIN catalog_sales cs ON cs.cs_bill_addr_sk = ca.ca_address_sk
            AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
        JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
            AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
        JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
        JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN inventory i ON i.inv_date_sk = d_ss.d_date_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        d_ss.d_year = 2001
        AND sm.sm_type = 'AIR'
        AND ib.ib_lower_bound >= 50000
        AND cs.cs_ext_sales_price > 1000
        AND ss.ss_quantity > 1
        AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
              AND wr.wr_return_amt > 0
        )
    GROUP BY
        sm.sm_ship_mode_id,
        sm.sm_type,
        d_ss.d_year
)
SELECT
    ship_type,
    AVG(store_net_profit_sum + catalog_net_profit_sum + web_net_profit_sum) AS avg_total_net_profit,
    SUM(store_sales_sum + catalog_sales_sum + web_sales_sum) AS total_sales_all,
    AVG(total_inventory) AS avg_total_inventory,
    COUNT(*) AS ship_mode_count
FROM per_ship_year
WHERE (store_net_profit_sum + catalog_net_profit_sum + web_net_profit_sum) > 5000
GROUP BY ship_type
ORDER BY avg_total_net_profit DESC
LIMIT 100
