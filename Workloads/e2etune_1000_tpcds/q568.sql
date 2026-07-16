WITH sales_by_demo AS (
    SELECT
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_net_profit) AS avg_profit,
        COUNT(*) AS sales_transactions
    FROM store_sales AS ss
    JOIN household_demographics AS hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count = 2
      AND hd.hd_vehicle_count >= 1
      AND ss.ss_quantity > 0
    GROUP BY hd.hd_buy_potential, hd.hd_vehicle_count
)
SELECT
    sbd.hd_buy_potential,
    sbd.hd_vehicle_count,
    sbd.total_profit,
    sbd.avg_profit,
    sbd.sales_transactions,
    RANK() OVER (ORDER BY sbd.total_profit DESC) AS profit_rank,
    SUM(sbd.total_profit) OVER (
        ORDER BY sbd.hd_buy_potential
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit_by_buy_potential
FROM sales_by_demo AS sbd
ORDER BY sbd.total_profit DESC
LIMIT 20
