WITH sales_by_income AS (
    SELECT ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(cs.cs_net_profit) AS total_profit,
           AVG(cs.cs_ext_ship_cost) AS avg_ship_cost,
           COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
           COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
      ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib
      ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_ext_ship_cost > 500
      AND hd_ship.hd_vehicle_count >= 2
      AND cs.cs_ship_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT ib_income_band_sk,
       CONCAT('Band ', CAST(ib_lower_bound AS VARCHAR), '-', CAST(ib_upper_bound AS VARCHAR)) AS income_band_desc,
       total_profit,
       avg_ship_cost,
       distinct_customers,
       sales_cnt,
       RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM sales_by_income
ORDER BY profit_rank
LIMIT 10
