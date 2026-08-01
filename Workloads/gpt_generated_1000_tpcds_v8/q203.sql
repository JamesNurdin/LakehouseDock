/* goal: calculate total sales, total tax and average profit per store and buying‑potential segment, with multiple filters, subtotals, a ranking column and a deduplication step via UNION */
WITH base AS (
    SELECT
        ss.ss_store_sk,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM store_sales ss
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_list_price >= 30.00                         -- predicate 1
      AND ss.ss_list_price <= 110.00                        -- predicate 2
      AND ss.ss_wholesale_cost > 20.00                      -- predicate 3
      AND ss.ss_quantity BETWEEN 1 AND 10                  -- predicate 4
      AND hd.hd_vehicle_count IN (1, 2, 3, 4)              -- predicate 5
      AND hd.hd_dep_count <> -1                            -- predicate 6
),
agg_all AS (
    SELECT
        b.ss_store_sk,
        b.hd_buy_potential,
        SUM(b.ss_ext_sales_price) AS total_sales,
        SUM(b.ss_ext_tax) AS total_tax,
        AVG(b.ss_net_profit) AS avg_profit,
        COUNT(*) AS cnt
    FROM base b
    GROUP BY ROLLUP (b.ss_store_sk, b.hd_buy_potential)
),
agg_vehicle_2 AS (
    SELECT
        b.ss_store_sk,
        b.hd_buy_potential,
        SUM(b.ss_ext_sales_price) AS total_sales,
        SUM(b.ss_ext_tax) AS total_tax,
        AVG(b.ss_net_profit) AS avg_profit,
        COUNT(*) AS cnt
    FROM base b
    WHERE b.hd_vehicle_count = 2                     -- extra filter for the second branch
    GROUP BY ROLLUP (b.ss_store_sk, b.hd_buy_potential)
),
unioned AS (
    SELECT ss_store_sk, hd_buy_potential, total_sales, total_tax, avg_profit, cnt FROM agg_all
    UNION DISTINCT
    SELECT ss_store_sk, hd_buy_potential, total_sales, total_tax, avg_profit, cnt FROM agg_vehicle_2
)
SELECT
    u.ss_store_sk,
    u.hd_buy_potential,
    SUM(u.total_sales) AS sum_sales,
    SUM(u.total_tax)   AS sum_tax,
    AVG(u.avg_profit)  AS avg_profit_over_groups,
    SUM(u.cnt)         AS total_cnt,
    ROW_NUMBER() OVER (ORDER BY SUM(u.total_sales) DESC) AS row_num
FROM unioned u
GROUP BY CUBE (u.ss_store_sk, u.hd_buy_potential)
HAVING SUM(u.total_sales) > 1000.00
ORDER BY sum_sales DESC
LIMIT 100
