-- Goal: Identify high‑profit demographic segments (by income band and vehicle ownership) and rank them by total sales while excluding customers with unusually high overall profit.
WITH sales_demo AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_wholesale_cost,
        ss.ss_list_price,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_coupon_amt,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_hdemo_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 60000
      AND ib.ib_upper_bound <= 150000
      AND hd.hd_dep_count >= 2
      AND ss.ss_ext_tax > 10
      AND ss.ss_wholesale_cost BETWEEN 10 AND 100
      AND ss.ss_quantity > 0
),
customer_exclusion AS (
    SELECT ss_customer_sk
    FROM store_sales
    GROUP BY ss_customer_sk
    HAVING SUM(ss_net_profit) > 10000
),
aggregated AS (
    SELECT
        sd.hd_income_band_sk,
        sd.hd_vehicle_count,
        SUM(sd.ss_ext_sales_price) AS total_ext_sales,
        SUM(sd.ss_net_profit) AS total_net_profit
    FROM sales_demo sd
    WHERE NOT EXISTS (
        SELECT 1
        FROM customer_exclusion ce
        WHERE ce.ss_customer_sk = sd.ss_customer_sk
    )
    GROUP BY ROLLUP (sd.hd_income_band_sk, sd.hd_vehicle_count)
    HAVING sd.hd_income_band_sk IS NOT NULL
),
ranked AS (
    SELECT
        hd_income_band_sk,
        hd_vehicle_count,
        total_ext_sales,
        total_net_profit,
        CASE
            WHEN total_net_profit > 5000 THEN 'HIGH'
            WHEN total_net_profit BETWEEN 1000 AND 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category,
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_ext_sales DESC) AS sales_rank,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS overall_profit_rank
    FROM aggregated
)
SELECT
    hd_income_band_sk,
    hd_vehicle_count,
    total_ext_sales,
    total_net_profit,
    profit_category,
    sales_rank,
    overall_profit_rank
FROM ranked
ORDER BY total_ext_sales DESC
LIMIT 100
