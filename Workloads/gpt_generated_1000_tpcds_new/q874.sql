WITH base AS (
    SELECT
        d.d_year,
        cc.cc_name,
        r.r_reason_desc,
        c.c_customer_id,
        hd.hd_income_band_sk,
        cr.cr_return_amount,
        ss.ss_net_paid,
        ws.ws_net_paid AS web_net_paid,
        w.w_warehouse_name,
        wp.wp_type,
        we.web_name,
        CASE 
            WHEN ss.ss_net_paid + ws.ws_net_paid - cr.cr_return_amount > 10000 THEN 'High'
            ELSE 'Low'
        END AS profit_level,
        ws_l.total_customer_web_sales
    FROM call_center cc
    JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                         AND sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
                     AND wp.wp_creation_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT SUM(ws2.ws_ext_sales_price) AS total_customer_web_sales
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
    ) ws_l
    WHERE d.d_year = 2000
      AND cc.cc_state = 'CA'
      AND w.w_country = 'United States'
      AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'
      AND hd.hd_income_band_sk BETWEEN 2 AND 5
      AND cr.cr_return_amount > 100
),
agg1 AS (
    SELECT
        d_year,
        cc_name,
        r_reason_desc,
        profit_level,
        SUM(ss_net_paid) AS sum_store_sales,
        SUM(web_net_paid) AS sum_web_sales,
        SUM(cr_return_amount) AS sum_returns,
        (SUM(ss_net_paid) + SUM(web_net_paid) - SUM(cr_return_amount)) AS net_profit,
        SUM(total_customer_web_sales) AS sum_customer_web_sales
    FROM base
    GROUP BY d_year, cc_name, r_reason_desc, profit_level
),
agg2 AS (
    SELECT
        d_year,
        cc_name,
        net_profit,
        CASE 
            WHEN net_profit > 20000 THEN 'Very High'
            WHEN net_profit > 10000 THEN 'High'
            ELSE 'Medium'
        END AS profit_category
    FROM agg1
),
final_high AS (
    SELECT d_year, cc_name, net_profit, profit_category
    FROM agg2
    WHERE profit_category IN ('Very High', 'High')
),
final_low AS (
    SELECT d_year, cc_name, net_profit, profit_category
    FROM agg2
    WHERE profit_category = 'Medium' AND net_profit < 8000
),
combined AS (
    SELECT * FROM final_high
    EXCEPT
    SELECT * FROM final_low
)
SELECT *
FROM combined
ORDER BY net_profit DESC
OFFSET 10
LIMIT 100
