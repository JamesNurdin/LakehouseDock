WITH
  combined_sales AS (
    SELECT
      i.i_item_sk,
      i.i_category_id,
      i.i_class_id,
      i.i_brand,
      cp.cp_department,
      sm.sm_type,
      td.t_hour,
      cd.cd_gender,
      SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
      SUM(cs.cs_net_profit) AS catalog_profit,
      SUM(ss.ss_ext_sales_price) AS store_sales_amount,
      SUM(ss.ss_net_profit) AS store_profit,
      SUM(cs.cs_quantity) + SUM(ss.ss_quantity) AS total_quantity,
      SUM(
        CASE
          WHEN (cs.cs_ext_sales_price + ss.ss_ext_sales_price) = 0 THEN 0
          ELSE (cs.cs_net_profit + ss.ss_net_profit) / (cs.cs_ext_sales_price + ss.ss_ext_sales_price)
        END
      ) AS profit_margin_sum,
      COUNT(DISTINCT sm.sm_ship_mode_id) AS distinct_ship_modes
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
      AND ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_category_id IN (10, 5)               -- filter 1
      AND sm.sm_type = 'AIR'                       -- filter 2
      AND td.t_hour BETWEEN 8 AND 12               -- filter 3
      AND cd.cd_gender = 'M'                       -- filter 4
      AND inv.inv_quantity_on_hand > 1000          -- filter 5
    GROUP BY
      i.i_item_sk,
      i.i_category_id,
      i.i_class_id,
      i.i_brand,
      cp.cp_department,
      sm.sm_type,
      td.t_hour,
      cd.cd_gender
  ),
  catalog_item_keys AS (
    SELECT DISTINCT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour >= 9 AND td.t_hour <= 17
  ),
  store_item_keys AS (
    SELECT DISTINCT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour >= 9 AND td.t_hour <= 17
  ),
  intersected_items AS (
    SELECT item_sk FROM catalog_item_keys
    INTERSECT
    SELECT item_sk FROM store_item_keys
  )
SELECT
  cs.i_category_id,
  cs.i_class_id,
  cs.i_brand,
  cs.cp_department,
  cs.sm_type,
  AVG(cs.catalog_sales_amount + cs.store_sales_amount) AS avg_total_sales,
  SUM(cs.catalog_profit + cs.store_profit) AS total_profit,
  SUM(cs.profit_margin_sum) / NULLIF(SUM(cs.total_quantity), 0) AS avg_profit_margin,
  cs.distinct_ship_modes
FROM combined_sales cs
WHERE cs.i_item_sk IN (SELECT item_sk FROM intersected_items)
GROUP BY
  cs.i_category_id,
  cs.i_class_id,
  cs.i_brand,
  cs.cp_department,
  cs.sm_type,
  cs.distinct_ship_modes
HAVING SUM(cs.total_quantity) > 5000
ORDER BY avg_total_sales DESC
LIMIT 100
