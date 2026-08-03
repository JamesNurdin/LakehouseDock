WITH
  item_sales_agg AS (
    SELECT
      cs_item_sk,
      SUM(cs_ext_sales_price) AS total_sales,
      AVG(cs_ext_discount_amt) AS avg_discount,
      COUNT(*) AS sales_cnt
    FROM catalog_sales
    GROUP BY cs_item_sk
  ),
  small_dim AS (
    SELECT DISTINCT hd_buy_potential
    FROM household_demographics
    WHERE hd_buy_potential IN ('0-500', '1001-5000')
  ),
  scalar_max_warehouse AS (
    SELECT MAX(w_warehouse_sq_ft) AS max_sq_ft
    FROM warehouse
    WHERE w_country = 'United States'
  ),
  customer_exclusions AS (
    SELECT c_customer_sk
    FROM customer
    WHERE c_birth_year < 1950
    EXCEPT
    SELECT c.c_customer_sk
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 100000
  )
SELECT
  i.i_item_id,
  i.i_brand,
  cp.cp_department,
  w.w_warehouse_name,
  isagg.total_sales,
  isagg.avg_discount,
  isagg.sales_cnt,
  ROW_NUMBER() OVER (ORDER BY isagg.total_sales DESC) AS rn
FROM item_sales_agg isagg
JOIN item i ON isagg.cs_item_sk = i.i_item_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2 AS dummy) v
CROSS JOIN small_dim sd
WHERE
  td.t_hour BETWEEN 9 AND 17
  AND i.i_brand = 'Brand#123'
  AND w.w_state = 'CA'
  AND hd.hd_vehicle_count >= 1
  AND ib.ib_upper_bound <= 50000
  AND cs.cs_wholesale_cost < (SELECT max_sq_ft FROM scalar_max_warehouse)
  AND c.c_customer_sk NOT IN (SELECT c_customer_sk FROM customer_exclusions)
LIMIT 100
