WITH bill_addr_keys AS (
   SELECT DISTINCT cs_bill_addr_sk AS addr_sk
   FROM catalog_sales
   WHERE cs_coupon_amt > 500
),
ship_addr_keys AS (
   SELECT DISTINCT cs_ship_addr_sk AS addr_sk
   FROM catalog_sales
   WHERE cs_coupon_amt < 300
),
addr_diff AS (
   SELECT addr_sk
   FROM bill_addr_keys
   EXCEPT
   SELECT addr_sk FROM ship_addr_keys
)
SELECT
   ca_bill.ca_city AS bill_city,
   ca_ship.ca_city AS ship_city,
   cd_bill.cd_gender AS bill_gender,
   cd_ship.cd_gender AS ship_gender,
   hd_bill.hd_income_band_sk,
   hd_ship.hd_vehicle_count,
   sm.sm_type,
   sm2.sm_code,
   SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
   ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rn,
   (
      SELECT COUNT(DISTINCT cs_inner.cs_order_number)
      FROM catalog_sales cs_inner
      WHERE cs_inner.cs_bill_addr_sk = ca_bill.ca_address_sk
   ) AS orders_per_bill_addr
FROM catalog_sales cs
LEFT JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN ship_mode sm2
  ON cs.cs_ship_mode_sk = sm2.sm_ship_mode_sk
FULL OUTER JOIN addr_diff ad
  ON cs.cs_bill_addr_sk = ad.addr_sk
WHERE cs.cs_ext_sales_price > 1000
GROUP BY
   ca_bill.ca_city,
   ca_ship.ca_city,
   cd_bill.cd_gender,
   cd_ship.cd_gender,
   hd_bill.hd_income_band_sk,
   hd_ship.hd_vehicle_count,
   sm.sm_type,
   sm2.sm_code,
   ca_bill.ca_address_sk
ORDER BY total_ext_sales_price DESC
LIMIT 100
