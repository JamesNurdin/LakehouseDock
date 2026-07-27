WITH store_sales_agg AS (
    SELECT
        ss_customer_sk,
        ss_sold_date_sk,
        SUM(ss_net_paid) AS store_net_paid,
        SUM(ss_net_profit) AS store_net_profit
    FROM store_sales
    GROUP BY ss_customer_sk, ss_sold_date_sk
)
SELECT
    d.d_year AS year,
    cd.cd_gender AS gender,
    SUM(ssa.store_net_profit) AS total_store_profit,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    (SUM(ssa.store_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) + SUM(cr.cr_net_loss)) AS total_combined_profit
FROM store_sales_agg ssa
JOIN customer c ON ssa.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN date_dim d ON ssa.ss_sold_date_sk = d.d_date_sk
JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
WHERE d.d_year = 2001
  AND cd.cd_gender = 'M'
  AND sm.sm_type = 'AIR'
  AND ssa.store_net_paid > 1000
GROUP BY d.d_year, cd.cd_gender
HAVING (SUM(ssa.store_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) + SUM(cr.cr_net_loss)) > 5000
ORDER BY total_combined_profit DESC
