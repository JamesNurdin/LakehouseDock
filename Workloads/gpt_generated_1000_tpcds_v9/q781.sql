WITH combined AS (
  SELECT
    MAX('Bill') AS demographic_source,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_ship_cost) AS total_ext_ship_cost,
    AVG(cs.cs_quantity) AS avg_quantity,
    (SELECT SUM(cs_ext_ship_cost) FROM catalog_sales) AS total_ship_cost_all
  FROM catalog_sales cs
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cs.cs_ext_ship_cost > 500
    AND cs.cs_sold_date_sk BETWEEN 2452365 AND 2452405
  GROUP BY GROUPING SETS (
    (hd.hd_buy_potential, hd.hd_vehicle_count),
    (hd.hd_buy_potential),
    ()
  )
  UNION
  SELECT
    MAX('Ship') AS demographic_source,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_ship_cost) AS total_ext_ship_cost,
    AVG(cs.cs_quantity) AS avg_quantity,
    (SELECT SUM(cs_ext_ship_cost) FROM catalog_sales) AS total_ship_cost_all
  FROM catalog_sales cs
  JOIN household_demographics hd
    ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
  WHERE cs.cs_ext_ship_cost > 500
    AND cs.cs_sold_date_sk BETWEEN 2452406 AND 2452445
    AND cs.cs_bill_customer_sk IN (
         SELECT cs_bill_customer_sk
         FROM catalog_sales
         WHERE cs_list_price > 150
    )
  GROUP BY GROUPING SETS (
    (hd.hd_buy_potential, hd.hd_vehicle_count),
    (hd.hd_buy_potential),
    ()
  )
)
SELECT
    demographic_source,
    hd_buy_potential,
    hd_vehicle_count,
    total_net_profit,
    total_ext_ship_cost,
    avg_quantity,
    total_ship_cost_all
FROM combined
ORDER BY
    demographic_source,
    hd_buy_potential,
    hd_vehicle_count,
    total_net_profit DESC
LIMIT 100
