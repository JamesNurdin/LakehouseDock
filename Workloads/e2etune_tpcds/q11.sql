WITH filtered_customers AS (
    SELECT c.c_customer_sk,
           c.c_current_hdemo_sk,
           c.c_birth_month,
           c.c_salutation
    FROM customer c
    WHERE c.c_salutation IN ('Mr.', 'Mrs.')
      AND c.c_birth_month IN (4, 7, 10)
),
agg AS (
    SELECT
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        fc.c_birth_month,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
        SUM(wp.wp_char_count) AS total_char_count,
        AVG(wp.wp_char_count) AS avg_char_count
    FROM filtered_customers fc
    JOIN web_page wp ON wp.wp_customer_sk = fc.c_customer_sk
    JOIN household_demographics hd ON fc.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE wp.wp_type = 'content'
    GROUP BY hd.hd_buy_potential, hd.hd_income_band_sk, fc.c_birth_month
)
SELECT
    hd_buy_potential,
    hd_income_band_sk,
    c_birth_month,
    distinct_pages,
    total_char_count,
    avg_char_count,
    RANK() OVER (ORDER BY distinct_pages DESC) AS page_rank
FROM agg
ORDER BY distinct_pages DESC
LIMIT 100
