WITH sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY ss.ss_sold_date_sk,
             ss.ss_customer_sk,
             ss.ss_store_sk,
             ss.ss_ticket_number,
             s.s_store_name,
             d.d_year
)
SELECT
    s.s_store_name,
    d.d_year,
    sa.total_net_profit,
    sa.sales_cnt,
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_type,
    r.r_reason_desc,
    wp.wp_url,
    c.c_first_name,
    c.c_last_name,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY sa.total_net_profit DESC) AS rn_year,
    RANK() OVER (ORDER BY sa.total_net_profit DESC) AS overall_rank
FROM sales_agg sa
JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN customer c ON sa.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
                     AND sr.sr_returned_date_sk = d.d_date_sk
                     AND sr.sr_ticket_number = sa.ss_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    d.d_year = 2001
    AND c.c_birth_day IN (14, 25)
    AND s.s_state = 'CA'
    AND r.r_reason_desc = 'Customer Not Interested'
    AND sm.sm_type = 'AIR'
    AND EXISTS (
        SELECT 1
        FROM web_site ws
        WHERE ws.web_site_id = 'site-001'
          AND ws.web_open_date_sk = d.d_date_sk
    )
ORDER BY overall_rank, s.s_store_name
LIMIT 100
