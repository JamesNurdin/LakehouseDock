WITH male_sales AS (
    SELECT
        d.d_year AS sales_year,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd.cd_gender = 'M'
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING SUM(ss.ss_net_profit) > 10000
),
female_sales AS (
    SELECT
        d.d_year AS sales_year,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd.cd_gender = 'F'
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    sales_year,
    income_lower,
    income_upper,
    total_net_profit,
    sales_count
FROM male_sales
UNION ALL
SELECT
    sales_year,
    income_lower,
    income_upper,
    total_net_profit,
    sales_count
FROM female_sales
