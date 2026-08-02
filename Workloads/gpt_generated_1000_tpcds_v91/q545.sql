WITH store_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        SUM(ss.ss_net_paid) AS store_net_paid,
        MAX(d_sales.d_date) AS store_last_date
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d_sales.d_year = 2001
      AND t_sales.t_hour BETWEEN 9 AND 17
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY ss.ss_customer_sk
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid) AS web_net_paid,
        MAX(d_web.d_date) AS web_last_date
    FROM web_sales ws
    JOIN date_dim d_web ON ws.ws_sold_date_sk = d_web.d_date_sk
    JOIN time_dim t_web ON ws.ws_sold_time_sk = t_web.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d_web.d_year = 2001
      AND t_web.t_hour BETWEEN 9 AND 17
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY ws.ws_bill_customer_sk
),
combined_customers AS (
    SELECT DISTINCT customer_sk FROM store_agg
    UNION
    SELECT DISTINCT customer_sk FROM web_agg
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    COALESCE(sa.store_net_paid, 0) + COALESCE(wa.web_net_paid, 0) AS total_net_paid,
    GREATEST(
        COALESCE(sa.store_last_date, DATE '1900-01-01'),
        COALESCE(wa.web_last_date, DATE '1900-01-01')
    ) AS most_recent_purchase_date,
    ROW_NUMBER() OVER (
        ORDER BY COALESCE(sa.store_net_paid, 0) + COALESCE(wa.web_net_paid, 0) DESC
    ) AS purchase_rank,
    (
        SELECT COALESCE(SUM(sr.sr_net_loss), 0)
        FROM store_returns sr
        JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
        WHERE sr.sr_customer_sk = c.c_customer_sk
          AND d_ret.d_year = 2001
    ) AS total_returns_amount,
    wp_stats.distinct_page_visits
FROM combined_customers cc
JOIN customer c ON cc.customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN store_agg sa ON sa.customer_sk = c.c_customer_sk
LEFT JOIN web_agg wa ON wa.customer_sk = c.c_customer_sk
CROSS JOIN LATERAL (
    SELECT COUNT(DISTINCT wp2.wp_url) AS distinct_page_visits
    FROM web_sales ws2
    JOIN web_page wp2 ON ws2.ws_web_page_sk = wp2.wp_web_page_sk
    WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
) AS wp_stats
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_customer_sk = c.c_customer_sk
)
  AND c.c_birth_country = 'United States'
ORDER BY total_net_paid DESC
LIMIT 100
