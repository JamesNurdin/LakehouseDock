WITH store_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2002
    GROUP BY ss.ss_customer_sk
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2002
    GROUP BY ws.ws_bill_customer_sk
),
customer_base AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_preferred_cust_flag,
        hd.hd_buy_potential,
        hd.hd_dep_count
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_email_address LIKE '%@example.com'
      AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND hd.hd_buy_potential = '>10000'
)
SELECT
    DISTINCT
    CONCAT(cb.c_first_name, ' ', cb.c_last_name) AS full_name,
    cb.c_email_address,
    CASE WHEN cb.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_type,
    cb.hd_buy_potential,
    COALESCE(sa.store_net_paid, 0) + COALESCE(wa.web_net_paid, 0) AS total_net_paid,
    COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) AS total_net_profit,
    (COALESCE(sa.store_net_paid, 0) + COALESCE(wa.web_net_paid, 0)) / NULLIF(
        (SELECT AVG(total_sales) FROM (
            SELECT ss2.ss_net_paid AS total_sales FROM store_sales ss2
            UNION ALL
            SELECT ws2.ws_net_paid FROM web_sales ws2
        ) AS all_sales), 0) AS relative_to_avg_ratio,
    REGEXP_EXTRACT(cb.c_email_address, '@(.+)$', 1) AS email_domain
FROM customer_base cb
LEFT JOIN store_agg sa ON cb.c_customer_sk = sa.customer_sk
LEFT JOIN web_agg wa ON cb.c_customer_sk = wa.customer_sk
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws3
    WHERE ws3.ws_bill_customer_sk = cb.c_customer_sk
      AND regexp_like(CAST(ws3.ws_sales_price AS VARCHAR), '^\\d+\\.\\d{2}$')
)
ORDER BY total_net_paid DESC
LIMIT 100
