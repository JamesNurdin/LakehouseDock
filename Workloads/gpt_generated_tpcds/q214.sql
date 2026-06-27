WITH date_2000 AS (
    SELECT
        d_date_sk,
        d_year,
        d_month_seq,
        d_date
    FROM date_dim
    WHERE d_year = 2000
),
store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        p.p_promo_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt
    FROM store_sales ss
    JOIN date_2000 d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, d.d_month_seq, p.p_promo_name
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        p.p_promo_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_2000 d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, d.d_month_seq, p.p_promo_name
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        p.p_promo_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_2000 d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, d.d_month_seq, p.p_promo_name
)
SELECT
    year,
    month,
    promo_name,
    SUM(total_net_paid) AS total_net_paid,
    SUM(total_net_profit) AS total_net_profit,
    SUM(order_cnt) AS total_orders
FROM (
    SELECT d_year AS year, d_month_seq AS month, p_promo_name AS promo_name, total_net_paid, total_net_profit, order_cnt
    FROM store_sales_agg
    UNION ALL
    SELECT d_year, d_month_seq, p_promo_name, total_net_paid, total_net_profit, order_cnt
    FROM catalog_sales_agg
    UNION ALL
    SELECT d_year, d_month_seq, p_promo_name, total_net_paid, total_net_profit, order_cnt
    FROM web_sales_agg
) combined
GROUP BY year, month, promo_name
ORDER BY year, month, total_net_paid DESC
LIMIT 100
