WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_net_profit,
        s.s_store_name,
        s.s_city,
        d.d_year,
        d.d_month_seq,
        p.p_promo_name,
        p.p_channel_dmail,
        c.c_customer_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE p.p_channel_dmail = 'Y'
      AND s.s_city LIKE '%York%'
      AND regexp_like(p.p_promo_name, '[0-9]{3,}')
      AND NOT EXISTS (
            SELECT 1 FROM store_returns sr
            WHERE sr.sr_ticket_number = ss.ss_ticket_number
              AND sr.sr_returned_date_sk = ss.ss_sold_date_sk
        )
)
SELECT
    fs.s_store_name,
    fs.d_year,
    fs.d_month_seq,
    lc.promo_code,
    SUM(fs.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT fs.c_customer_sk) AS distinct_customers,
    CASE
        WHEN SUM(fs.ss_net_profit) > 100000 THEN 'High'
        WHEN SUM(fs.ss_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = fs.ss_store_sk
    ) AS avg_store_profit
FROM filtered_sales fs
CROSS JOIN LATERAL (
    SELECT regexp_extract(fs.p_promo_name, '(\\d+)', 1) AS promo_code
) AS lc
GROUP BY
    fs.s_store_name,
    fs.d_year,
    fs.d_month_seq,
    lc.promo_code,
    fs.ss_store_sk
ORDER BY total_net_profit DESC
LIMIT 100
