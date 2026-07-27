WITH filtered AS (
    SELECT
        s.s_store_name,
        sm.sm_type,
        (SELECT r.r_reason_desc FROM reason r WHERE r.r_reason_sk = sr.sr_reason_sk) AS reason_desc,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(sr.sr_refunded_cash) AS total_refunds,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        AVG(ss.ss_quantity) AS avg_quantity,
        MIN(ss.ss_sales_price) AS min_sales_price,
        MAX(ss.ss_sales_price) AS max_sales_price
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
       AND ss.ss_ticket_number = sr.sr_ticket_number
       AND sr.sr_store_sk = s.s_store_sk
       AND sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE c.c_salutation = 'Mr.'
      AND cd.cd_gender = 'M'
      AND s.s_state = 'CA'
      AND s.s_rec_start_date >= DATE '2000-01-01'
      AND s.s_rec_end_date <= DATE '2001-12-31'
      AND wp.wp_char_count BETWEEN 1000 AND 5000
      AND sm.sm_type = 'AIR'
      AND ws.ws_sold_date_sk = 2450809
      AND EXISTS (
          SELECT 1 FROM reason r
          WHERE r.r_reason_sk = sr.sr_reason_sk
            AND r.r_reason_desc = 'Damaged'
      )
    GROUP BY
        s.s_store_name,
        sm.sm_type,
        (SELECT r.r_reason_desc FROM reason r WHERE r.r_reason_sk = sr.sr_reason_sk)
)
SELECT *
FROM filtered
ORDER BY total_sales DESC
LIMIT 100
