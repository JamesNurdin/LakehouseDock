WITH profit_by_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS month_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS customers_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year IN (2020,2021)
    GROUP BY d.d_year, d.d_month_seq
),
top_promos AS (
    SELECT
        ss.ss_promo_sk,
        SUM(ss.ss_ext_sales_price) AS promo_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rn
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
    GROUP BY ss.ss_promo_sk
)
SELECT
    pbm.d_year,
    pbm.d_month_seq,
    pbm.month_profit,
    pbm.customers_count,
    p.p_promo_name,
    tp.promo_sales,
    CASE WHEN pbm.month_profit > 50000 THEN 'Strong' ELSE 'Weak' END AS profit_level
FROM profit_by_month pbm
LEFT JOIN top_promos tp ON tp.rn = 1
LEFT JOIN promotion p ON tp.ss_promo_sk = p.p_promo_sk
ORDER BY pbm.d_year DESC, pbm.d_month_seq
