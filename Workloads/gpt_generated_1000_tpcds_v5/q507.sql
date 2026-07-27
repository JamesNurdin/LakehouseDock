WITH filtered_sales AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity BETWEEN 1 AND 5
      AND cs.cs_net_paid > 0
)
SELECT
    td.t_sub_shift,
    ib.ib_lower_bound,
    hd.hd_buy_potential,
    SUM(fs.cs_net_paid) AS total_net_paid,
    AVG(fs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT fs.cs_order_number) AS distinct_orders,
    MIN(fs.cs_net_profit) AS min_profit,
    MAX(fs.cs_net_profit) AS max_profit
FROM filtered_sales fs
JOIN time_dim td ON fs.cs_sold_time_sk = td.t_time_sk
JOIN household_demographics hd ON fs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE td.t_sub_shift = 'morning'
  AND hd.hd_dep_count >= 2
  AND hd.hd_vehicle_count > 0
  AND ib.ib_lower_bound >= 100000
GROUP BY td.t_sub_shift, ib.ib_lower_bound, hd.hd_buy_potential
ORDER BY total_net_paid DESC
LIMIT 100
