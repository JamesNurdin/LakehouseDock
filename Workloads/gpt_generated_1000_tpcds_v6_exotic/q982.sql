WITH base AS (
    SELECT
        c.c_customer_id,
        c.c_last_name,
        c.c_birth_year,
        r.r_reason_desc,
        sm.sm_type,
        ws.ws_net_paid_inc_ship_tax,
        sr.sr_return_amt
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
              AND wp.wp_customer_sk = c.c_customer_sk
              AND wp.wp_type = 'article'
              AND wp.wp_rec_end_date > DATE '2000-01-01'
        )
      AND ws.ws_net_paid_inc_ship_tax > 1000
      AND sr.sr_return_quantity > 0
      AND c.c_birth_year BETWEEN 1950 AND 1990
      AND r.r_reason_desc IS NOT NULL
)
SELECT
    c_customer_id,
    c_last_name,
    sm_type,
    SUM(ws_net_paid_inc_ship_tax) AS total_sales,
    SUM(sr_return_amt) AS total_returns,
    SUM(ws_net_paid_inc_ship_tax) - SUM(sr_return_amt) AS net_amount,
    CASE
        WHEN SUM(ws_net_paid_inc_ship_tax) - SUM(sr_return_amt) > 5000 THEN 'High'
        ELSE 'Regular'
    END AS net_category,
    RANK() OVER (
        PARTITION BY sm_type
        ORDER BY (SUM(ws_net_paid_inc_ship_tax) - SUM(sr_return_amt)) DESC
    ) AS rank_in_ship_mode
FROM base
GROUP BY c_customer_id, c_last_name, sm_type
HAVING (SUM(ws_net_paid_inc_ship_tax) - SUM(sr_return_amt)) > 1000
ORDER BY net_amount DESC
LIMIT 100
