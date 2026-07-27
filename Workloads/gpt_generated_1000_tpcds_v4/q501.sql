WITH ss_agg AS (
    SELECT
        ss_hdemo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_ext_discount_amt) AS avg_discount,
        SUM(ss_quantity) AS total_quantity,
        MIN(ss_net_profit) AS min_profit,
        MAX(ss_net_profit) AS max_profit,
        COUNT(*) AS txn_count
    FROM tpcds.store_sales
    WHERE
        ss_list_price > 20.00
        AND ss_list_price < 60.00
        AND ss_ext_discount_amt BETWEEN 20.00 AND 500.00
        AND ss_ext_wholesale_cost > 100.00
        AND ss_quantity >= 1
        AND ss_net_paid_inc_tax > 0
    GROUP BY ss_hdemo_sk
)
SELECT
    hd.hd_demo_sk,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    agg.total_sales,
    agg.avg_discount,
    agg.total_quantity,
    agg.txn_count,
    agg.min_profit,
    agg.max_profit
FROM ss_agg agg
JOIN tpcds.household_demographics hd
    ON agg.ss_hdemo_sk = hd.hd_demo_sk
WHERE
    hd.hd_dep_count IN (1, 2, 4, 6, 9)
    AND hd.hd_vehicle_count >= 0
    AND hd.hd_vehicle_count <= 4
ORDER BY agg.total_sales DESC
LIMIT 100
