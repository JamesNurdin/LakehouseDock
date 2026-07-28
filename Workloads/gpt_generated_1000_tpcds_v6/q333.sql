WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_last_name,
        c.c_first_name,
        c.c_birth_year,
        ib.ib_upper_bound,
        cs.cs_order_number,
        cs.cs_net_paid,
        ws.ws_order_number,
        ws.ws_net_paid,
        sr.sr_ticket_number,
        sr.sr_return_amt,
        r.r_reason_desc,
        wp.wp_web_page_id,
        web.web_site_id,
        cs.cs_sold_date_sk,
        ws.ws_sold_date_sk,
        sr.sr_return_ship_cost
    FROM customer c
    LEFT JOIN catalog_sales cs
           ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws
           ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr
           ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN household_demographics hd
           ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN reason r
           ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp
           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site web
           ON ws.ws_web_site_sk = web.web_site_sk
    WHERE ib.ib_upper_bound <= 70000                                      -- predicate 1
      AND ( cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000               -- predicate 2 (catalog date range)
         OR ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000 )           -- predicate 2 (web date range)
      AND sr.sr_return_amt > 100                                          -- predicate 3
      AND r.r_reason_desc = 'Damaged'                                      -- predicate 4
),
sales_agg AS (
    SELECT
        c_customer_sk,
        c_last_name,
        c_first_name,
        SUM(cs_net_paid) AS total_catalog_sales,
        SUM(ws_net_paid) AS total_web_sales,
        SUM(COALESCE(cs_net_paid,0) + COALESCE(ws_net_paid,0)) AS total_sales_amount,
        'sales' AS record_type
    FROM base
    WHERE cs_net_paid IS NOT NULL OR ws_net_paid IS NOT NULL
    GROUP BY c_customer_sk, c_last_name, c_first_name
),
returns_agg AS (
    SELECT
        c_customer_sk,
        c_last_name,
        c_first_name,
        0 AS total_catalog_sales,
        0 AS total_web_sales,
        SUM(sr_return_amt) AS total_sales_amount,
        'returns' AS record_type
    FROM base
    WHERE sr_return_amt IS NOT NULL
    GROUP BY c_customer_sk, c_last_name, c_first_name
),
combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
)
SELECT
    c_customer_sk,
    c_last_name,
    c_first_name,
    record_type,
    total_sales_amount,
    SUM(total_sales_amount) OVER (
        ORDER BY total_sales_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,
    RANK() OVER (
        ORDER BY total_sales_amount DESC
    ) AS sales_rank
FROM combined
ORDER BY total_sales_amount DESC
LIMIT 100
