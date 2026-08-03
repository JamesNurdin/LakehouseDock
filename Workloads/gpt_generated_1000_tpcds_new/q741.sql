/*
  Goal: Produce a comparative, aggregated view of store and web sales by year, category and location/ship mode, 
        demonstrating deep joins, sampling, scalar subquery filtering, CASE logic, UNION DISTINCT, and pagination.
*/
WITH
  ss_agg AS (
    SELECT
      d1.d_year AS year,
      i1.i_category AS category,
      s1.s_state AS location,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS transactions,
      CASE
        WHEN s1.s_tax_percentage > 0.08 THEN 'HIGH_TAX'
        ELSE 'LOW_TAX'
      END AS tax_group
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)          -- sample 10% of store_sales rows
    JOIN date_dim d1
      ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN item i1
      ON ss.ss_item_sk = i1.i_item_sk
    JOIN store s1
      ON ss.ss_store_sk = s1.s_store_sk
    JOIN date_dim d_closed
      ON s1.s_closed_date_sk = d_closed.d_date_sk
    JOIN item i_extra               -- second alias of item for additional join clause
      ON ss.ss_item_sk = i_extra.i_item_sk
    WHERE s1.s_tax_percentage > (
          SELECT MAX(s2.s_tax_percentage)
          FROM store s2
          WHERE s2.s_country = 'United States'
        )
    GROUP BY d1.d_year,
             i1.i_category,
             s1.s_state,
             CASE
               WHEN s1.s_tax_percentage > 0.08 THEN 'HIGH_TAX'
               ELSE 'LOW_TAX'
             END
  ),

  ws_agg AS (
    SELECT
      d2.d_year AS year,
      i2.i_category AS category,
      sm.sm_type AS ship_mode,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(DISTINCT ws.ws_order_number) AS transactions,
      CASE
        WHEN sm.sm_type = 'AIR' THEN 'AIR_SHIP'
        ELSE 'OTHER_SHIP'
      END AS ship_group
    FROM web_sales ws
    JOIN date_dim d2
      ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN date_dim d_ship
      ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN item i2
      ON ws.ws_item_sk = i2.i_item_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY d2.d_year,
             i2.i_category,
             sm.sm_type,
             CASE
               WHEN sm.sm_type = 'AIR' THEN 'AIR_SHIP'
               ELSE 'OTHER_SHIP'
             END
  )
SELECT
  combined.year,
  combined.category,
  combined.location_or_ship,
  combined.total_sales,
  combined.total_profit,
  combined.transactions,
  combined.group_label
FROM (
  SELECT
    year,
    category,
    location AS location_or_ship,
    total_sales,
    total_profit,
    transactions,
    tax_group AS group_label
  FROM ss_agg
  UNION DISTINCT
  SELECT
    year,
    category,
    ship_mode AS location_or_ship,
    total_sales,
    total_profit,
    transactions,
    ship_group AS group_label
  FROM ws_agg
) AS combined
ORDER BY combined.total_sales DESC
OFFSET 10
LIMIT 100
