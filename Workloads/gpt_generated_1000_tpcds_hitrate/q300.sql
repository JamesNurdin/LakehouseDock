WITH filtered_sales AS (
    SELECT
        cs_bill_hdemo_sk,
        cs_ship_hdemo_sk,
        cs_wholesale_cost,
        cs_ext_sales_price,
        cs_quantity,
        cs_net_paid_inc_tax,
        cs_net_profit
    FROM tpcds.catalog_sales
    WHERE cs_wholesale_cost BETWEEN 5.95 AND 3500.00
      AND cs_quantity >= 1
      AND cs_ext_sales_price > 500.00
      AND cs_net_paid_inc_tax < 6000.00
      AND cs_net_profit > -1000.00
      AND cs_ship_date_sk IS NOT NULL
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN fs.cs_quantity > 10 THEN 'Bulk'
        ELSE 'Regular'
    END AS order_type,
    hd_bill.hd_vehicle_count AS bill_vehicle_cnt,
    hd_ship.hd_vehicle_count AS ship_vehicle_cnt,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    AVG(fs.cs_net_profit) AS avg_profit,
    COUNT(*) AS order_cnt,
    (SELECT MAX(ib2.ib_upper_bound) FROM tpcds.income_band ib2) AS max_income_band_upper
FROM filtered_sales fs
JOIN tpcds.household_demographics hd_bill
    ON fs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ship
    ON fs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd_bill.hd_dep_count BETWEEN 0 AND 5
  AND hd_ship.hd_vehicle_count IN (1, 2, 3, 4)
  AND ib.ib_upper_bound >= 50000
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN fs.cs_quantity > 10 THEN 'Bulk'
        ELSE 'Regular'
    END,
    hd_bill.hd_vehicle_count,
    hd_ship.hd_vehicle_count
ORDER BY total_sales DESC
LIMIT 100
