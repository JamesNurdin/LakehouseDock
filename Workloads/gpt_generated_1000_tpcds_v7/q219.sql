WITH sales_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE
            WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HIGH'
            WHEN SUM(ss.ss_net_profit) > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1990
      AND hd.hd_vehicle_count >= 0
      AND ca.ca_gmt_offset BETWEEN -5.00 AND 0.00
      AND wp.wp_image_count >= 2
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
category_agg AS (
    SELECT
        profit_category,
        AVG(total_profit) AS avg_profit_per_category,
        SUM(sales_cnt) AS total_sales
    FROM sales_agg
    GROUP BY profit_category
    HAVING SUM(sales_cnt) > 10
)
SELECT
    profit_category,
    avg_profit_per_category,
    total_sales
FROM category_agg
ORDER BY avg_profit_per_category DESC
LIMIT 100
