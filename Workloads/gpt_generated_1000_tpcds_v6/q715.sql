WITH promo_sales AS (
    SELECT
        d.d_year AS sales_year,
        'With Promo' AS promo_type,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 100000
      AND d.d_year BETWEEN 2020 AND 2022
      AND EXISTS (
            SELECT 1
            FROM store_sales ss2
            JOIN promotion p2 ON ss2.ss_promo_sk = p2.p_promo_sk
            WHERE ss2.ss_customer_sk = ss.ss_customer_sk
              AND ss2.ss_sold_date_sk = ss.ss_sold_date_sk
              AND p2.p_start_date_sk = p.p_start_date_sk
              AND p2.p_end_date_sk = p.p_end_date_sk
        )
    GROUP BY d.d_year
),
no_promo_sales AS (
    SELECT
        d.d_year AS sales_year,
        'No Promo' AS promo_type,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE p.p_promo_sk IS NULL
      AND ib.ib_upper_bound <= 100000
      AND d.d_year BETWEEN 2020 AND 2022
    GROUP BY d.d_year
)
SELECT sales_year,
       promo_type,
       total_net_profit
FROM promo_sales
UNION ALL
SELECT sales_year,
       promo_type,
       total_net_profit
FROM no_promo_sales
ORDER BY sales_year DESC,
         total_net_profit DESC
LIMIT 100
