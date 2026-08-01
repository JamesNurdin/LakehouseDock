WITH
  sales_sample AS (
    SELECT
      ss.cs_sold_date_sk,
      ss.cs_quantity,
      ss.cs_ext_ship_cost,
      ss.cs_net_profit,
      ss.cs_call_center_sk,
      ss.cs_warehouse_sk,
      ss.cs_order_number,
      ss.cs_bill_customer_sk,
      ss.cs_bill_cdemo_sk,
      ss.cs_ship_cdemo_sk,
      ss.cs_catalog_page_sk,
      ss.cs_item_sk
    FROM catalog_sales ss
    TABLESAMPLE BERNOULLI (5)
  ),

  intersect_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_ext_ship_cost > 800

    INTERSECT

    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity >= 20
  ),

  joined_data AS (
    SELECT
      ss.cs_order_number,
      ss.cs_sold_date_sk,
      ss.cs_quantity,
      ss.cs_ext_ship_cost,
      ss.cs_net_profit,
      ss.cs_call_center_sk,
      ss.cs_warehouse_sk,
      cp.cp_department,
      cp.cp_catalog_number,
      cd_bill.cd_gender   AS bill_gender,
      cd_ship.cd_gender   AS ship_gender,
      i.i_brand,
      i.i_category,
      i.i_category_id,
      i.i_color,
      i.i_current_price,
      i.i_manufact,
      cat_stats.avg_price_category,
      CASE WHEN ss.cs_net_profit > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_indicator,
      (
        SELECT SUM(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = ss.cs_bill_customer_sk
          AND cs2.cs_sold_date_sk = ss.cs_sold_date_sk
      ) AS total_customer_profit_same_day
    FROM sales_sample ss
    JOIN catalog_page cp
      ON ss.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd_bill
      ON ss.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
      ON ss.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN item i
      ON ss.cs_item_sk = i.i_item_sk
    CROSS JOIN LATERAL (
      SELECT AVG(i2.i_current_price) AS avg_price_category
      FROM item i2
      WHERE i2.i_category_id = i.i_category_id
    ) AS cat_stats
    WHERE ss.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
      AND i.i_category_id IN (2, 5, 8)
      AND cp.cp_department = 'Electronics'
      AND ss.cs_ext_ship_cost > 500
  ),

  aggregated_data AS (
    SELECT
      i_brand,
      i_category,
      cp_department,
      profit_indicator,
      SUM(cs_quantity)           AS total_quantity,
      SUM(cs_net_profit)         AS total_net_profit,
      AVG(i_current_price)       AS avg_item_price,
      AVG(avg_price_category)    AS avg_category_price
    FROM joined_data
    GROUP BY ROLLUP (i_brand, i_category, cp_department, profit_indicator)
  )

SELECT
  ad.i_brand,
  ad.i_category,
  ad.cp_department,
  ad.profit_indicator,
  ad.total_quantity,
  ad.total_net_profit,
  ad.avg_item_price,
  ad.avg_category_price,
  ROW_NUMBER() OVER (PARTITION BY ad.i_brand ORDER BY ad.total_net_profit DESC) AS brand_profit_rank,
  RANK()       OVER (PARTITION BY ad.i_category ORDER BY ad.total_net_profit DESC) AS category_profit_rank
FROM aggregated_data ad
ORDER BY ad.total_net_profit DESC
LIMIT 100
