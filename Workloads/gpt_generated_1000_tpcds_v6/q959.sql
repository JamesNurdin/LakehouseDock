WITH sales_hdem AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_ship_hdemo_sk,
    cs.cs_net_paid_inc_ship,
    cs.cs_coupon_amt,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    hd.hd_buy_potential
  FROM tpcds.catalog_sales cs
  JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cs.cs_ship_hdemo_sk IN (1311, 5664, 6622, 4395)
    AND cs.cs_net_paid_inc_ship > 1000
    AND cs.cs_coupon_amt BETWEEN 50 AND 2000
    AND hd.hd_dep_count >= 2
    AND hd.hd_vehicle_count > 0
)
SELECT
  hd_buy_potential,
  hd_dep_count,
  SUM(cs_ext_sales_price) AS total_sales,
  SUM(cs_quantity) AS total_quantity,
  RANK() OVER (PARTITION BY hd_buy_potential ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank,
  CASE
    WHEN SUM(cs_ext_sales_price) > 5000 THEN 'High'
    WHEN SUM(cs_ext_sales_price) > 2000 THEN 'Medium'
    ELSE 'Low'
  END AS sales_category
FROM sales_hdem
GROUP BY ROLLUP (hd_buy_potential, hd_dep_count)
HAVING SUM(cs_ext_sales_price) IS NOT NULL
ORDER BY hd_buy_potential, sales_rank
LIMIT 100
