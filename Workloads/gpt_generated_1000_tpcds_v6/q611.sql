/* goal: Compare total sales and profit by household buying potential across catalog and web channels, excluding households that have more than two vehicles, and show subtotals */
WITH catalog_agg AS (
    SELECT
        hd.hd_buy_potential AS buy_potential,
        cs.cs_ext_sales_price   AS net_sales,
        cs.cs_net_profit        AS profit
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ext_sales_price > 5000
      AND NOT EXISTS (
          SELECT 1
          FROM household_demographics hd2
          WHERE hd2.hd_demo_sk = cs.cs_ship_hdemo_sk
            AND hd2.hd_vehicle_count > 2
      )
),
web_agg AS (
    SELECT
        hd.hd_buy_potential AS buy_potential,
        ws.ws_ext_sales_price   AS net_sales,
        ws.ws_net_profit        AS profit
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_ext_sales_price > 5000
      AND NOT EXISTS (
          SELECT 1
          FROM household_demographics hd2
          WHERE hd2.hd_demo_sk = ws.ws_ship_hdemo_sk
            AND hd2.hd_vehicle_count > 2
      )
)
SELECT
    buy_potential,
    SUM(net_sales) AS total_sales,
    SUM(profit)    AS total_profit,
    COUNT(*)       AS txn_count,
    GROUPING(buy_potential) AS grouping_indicator
FROM (
    SELECT buy_potential, net_sales, profit FROM catalog_agg
    UNION ALL
    SELECT buy_potential, net_sales, profit FROM web_agg
) u
GROUP BY GROUPING SETS ((buy_potential), ())
HAVING SUM(net_sales) > 10000
ORDER BY total_sales DESC, buy_potential
LIMIT 100
