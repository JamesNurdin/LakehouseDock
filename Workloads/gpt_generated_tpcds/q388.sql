WITH promo_store AS (
    SELECT
        p.p_promo_name AS promo_name,
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customers
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY p.p_promo_name, d.d_year
),
promo_web AS (
    SELECT
        p.p_promo_name AS promo_name,
        d.d_year AS year,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customers
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY p.p_promo_name, d.d_year
)
SELECT
    s.promo_name,
    s.year,
    s.store_sales,
    s.store_net_profit,
    s.store_customers,
    w.web_sales,
    w.web_net_profit,
    w.web_customers,
    (s.store_sales + w.web_sales) AS total_sales,
    (s.store_net_profit + w.web_net_profit) AS total_net_profit,
    (s.store_customers + w.web_customers) AS total_customers,
    (s.store_net_profit + w.web_net_profit) / (s.store_sales + w.web_sales) AS overall_profit_margin
FROM promo_store s
JOIN promo_web w ON s.promo_name = w.promo_name AND s.year = w.year
ORDER BY total_sales DESC
LIMIT 10
