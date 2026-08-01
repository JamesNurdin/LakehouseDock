WITH sales_agg AS (
    SELECT
        ss.ss_hdemo_sk,
        COUNT(*) AS transaction_count,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        MAX(ss.ss_sales_price) AS max_sales_price,
        MIN(ss.ss_sales_price) AS min_sales_price
    FROM store_sales ss
    WHERE
        ss.ss_sales_price > 20.00
        AND ss.ss_quantity >= 1
        AND ss.ss_wholesale_cost > 10.00
        AND ss.ss_net_profit > 0.00
        AND ss.ss_ext_discount_amt < 500.00
    GROUP BY ss.ss_hdemo_sk
    HAVING COUNT(*) >= 5
),
household_with_sales AS (
    SELECT
        h.hd_demo_sk,
        h.hd_income_band_sk,
        h.hd_buy_potential,
        h.hd_dep_count,
        h.hd_vehicle_count,
        COALESCE(sa.transaction_count, 0) AS transaction_count,
        COALESCE(sa.total_net_paid, 0) AS total_net_paid,
        COALESCE(sa.avg_net_profit, 0) AS avg_net_profit,
        COALESCE(sa.total_sales, 0) AS total_sales,
        COALESCE(sa.max_sales_price, 0) AS max_sales_price,
        COALESCE(sa.min_sales_price, 0) AS min_sales_price
    FROM household_demographics h
    LEFT JOIN sales_agg sa
        ON h.hd_demo_sk = sa.ss_hdemo_sk
    WHERE
        h.hd_income_band_sk IN (5, 10, 13, 16)
        AND h.hd_buy_potential IN ('0-500', '501-1000', '1001-5000', '>10000')
        AND h.hd_vehicle_count >= 1
        AND h.hd_dep_count <= 5
        AND h.hd_income_band_sk <> 1
),
ranked_households AS (
    SELECT
        hwd.*, 
        ROW_NUMBER() OVER (PARTITION BY hwd.hd_buy_potential ORDER BY hwd.avg_net_profit DESC) AS rank_within_potential,
        CASE
            WHEN hwd.total_sales > 10000 THEN 'High'
            WHEN hwd.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM household_with_sales hwd
)
SELECT
    rh.hd_demo_sk,
    rh.hd_income_band_sk,
    rh.hd_buy_potential,
    rh.hd_dep_count,
    rh.hd_vehicle_count,
    rh.transaction_count,
    rh.total_net_paid,
    rh.avg_net_profit,
    rh.total_sales,
    rh.max_sales_price,
    rh.sales_category,
    rh.rank_within_potential,
    (
        SELECT COUNT(*)
        FROM store_sales ss_sub
        WHERE ss_sub.ss_hdemo_sk = rh.hd_demo_sk
          AND ss_sub.ss_sales_price > rh.max_sales_price
    ) AS higher_price_sales_count
FROM ranked_households rh
WHERE rh.rank_within_potential <= 10
ORDER BY rh.hd_buy_potential, rh.rank_within_potential
LIMIT 100
