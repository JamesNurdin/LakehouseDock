WITH agg AS (
    SELECT
        cs.cs_ship_date_sk AS ship_date_sk,
        hd_bill.hd_buy_potential AS bill_buy_potential,
        hd_ship.hd_buy_potential AS ship_buy_potential,
        SUM(cs.cs_ext_sales_price) AS total_ext_sales,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt,
        AVG(cs.cs_ext_ship_cost) AS avg_ship_cost,
        CASE WHEN AVG(cs.cs_ext_ship_cost) > 2000 THEN 'High' ELSE 'Low' END AS ship_cost_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450869 AND 2450908
      AND cs.cs_ext_ship_cost > 1000
      AND hd_bill.hd_vehicle_count >= 1
      AND hd_ship.hd_buy_potential NOT LIKE 'Unknown%'
    GROUP BY cs.cs_ship_date_sk, hd_bill.hd_buy_potential, hd_ship.hd_buy_potential
)
SELECT
    ship_date_sk,
    bill_buy_potential,
    ship_buy_potential,
    ship_cost_category,
    total_ext_sales,
    total_net_profit,
    order_cnt,
    avg_ship_cost,
    RANK() OVER (PARTITION BY ship_date_sk ORDER BY total_net_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (ORDER BY total_ext_sales DESC) AS overall_sales_rank
FROM agg
ORDER BY ship_date_sk ASC, profit_rank ASC
LIMIT 100
