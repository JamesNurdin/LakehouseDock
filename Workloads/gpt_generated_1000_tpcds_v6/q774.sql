WITH avg_price AS (
    SELECT avg(cs_list_price) AS avg_lp
    FROM catalog_sales
)
SELECT DISTINCT
    src_type,
    hd_buy_potential,
    total_profit,
    avg_lp
FROM (
    SELECT
        'bill' AS src_type,
        hd.hd_buy_potential,
        SUM(cs.cs_net_profit) AS total_profit,
        (SELECT avg(cs_list_price) FROM catalog_sales) AS avg_lp
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_list_price > 60
      AND hd.hd_vehicle_count >= 2
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_item_sk = cs.cs_item_sk
            AND cs2.cs_quantity > 5
      )
    GROUP BY hd.hd_buy_potential
    HAVING SUM(cs.cs_net_profit) > 0

    UNION ALL

    SELECT
        'ship' AS src_type,
        hd.hd_buy_potential,
        SUM(cs.cs_net_profit) AS total_profit,
        (SELECT avg(cs_list_price) FROM catalog_sales) AS avg_lp
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_list_price > 60
      AND hd.hd_vehicle_count >= 2
      AND hd.hd_dep_count <> 0
    GROUP BY hd.hd_buy_potential
    HAVING SUM(cs.cs_net_profit) > 0
) combined
ORDER BY total_profit DESC
LIMIT 100
