WITH filtered_sales AS (
    SELECT DISTINCT
        cs_order_number,
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_bill_hdemo_sk,
        cs_ship_hdemo_sk,
        cs_catalog_page_sk,
        cs_ext_wholesale_cost,
        cs_quantity,
        cs_net_paid_inc_ship_tax,
        cs_net_profit
    FROM catalog_sales
    WHERE cs_ext_wholesale_cost > 1500
      AND cs_quantity >= 2
      AND cs_net_paid_inc_ship_tax < 2000
      AND cs_sold_date_sk BETWEEN 2450800 AND 2451200
      AND cs_sold_time_sk IN (64129, 29485, 43898)
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    fs.cs_ext_wholesale_cost,
    fs.cs_quantity,
    fs.cs_net_paid_inc_ship_tax,
    fs.cs_net_profit,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY fs.cs_net_profit DESC) AS profit_rank,
    CASE WHEN fs.cs_net_profit > (
            SELECT AVG(inner_cs.cs_net_profit)
            FROM catalog_sales inner_cs
            WHERE inner_cs.cs_catalog_page_sk = fs.cs_catalog_page_sk
        ) THEN 'Above Avg' ELSE 'Below Avg' END AS profit_vs_avg,
    (
        SELECT COUNT(*)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_hdemo_sk = fs.cs_bill_hdemo_sk
          AND cs2.cs_net_paid_inc_ship_tax > fs.cs_net_paid_inc_ship_tax
    ) AS higher_paid_count
FROM filtered_sales fs
JOIN catalog_page cp
    ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN household_demographics hd
    ON fs.cs_ship_hdemo_sk = hd.hd_demo_sk
WHERE cp.cp_catalog_number IN (101, 102)
  AND cp.cp_catalog_page_number > 5
  AND (hd.hd_vehicle_count IS NULL OR hd.hd_vehicle_count >= 0)
ORDER BY profit_rank
LIMIT 100
