WITH
  sales_returns AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_ship_mode_sk,
      cs.cs_warehouse_sk,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      ca_bill.ca_state          AS bill_state,
      ca_ship.ca_state          AS ship_state,
      d.d_year,
      sm.sm_code,
      w.w_warehouse_name,
      r.r_reason_desc
    FROM catalog_sales cs
    JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE d.d_year = 2001
  ),
  store_metrics AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_sold_date_sk,
      ss.ss_net_paid   AS store_net_paid,
      ss.ss_net_profit AS store_net_profit,
      s.s_store_name   AS store_name,
      d.d_year         AS sales_year,
      ca.ca_state      AS cust_state
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
  ),
  base AS (
    SELECT
      sr.d_year                         AS year,
      i1.inv_quantity_on_hand           AS current_qty,
      i2.inv_quantity_on_hand           AS past_qty,
      w.w_warehouse_name                AS warehouse_name,
      sm.sm_code                         AS ship_mode_code,
      CAST(NULL AS varchar)             AS store_name,
      sr.cs_net_paid                    AS total_sales,
      sr.cs_net_profit                  AS total_profit,
      sr.cr_return_amount               AS total_returns
    FROM sales_returns sr
    JOIN inventory i1
      ON sr.cs_sold_date_sk = i1.inv_date_sk
     AND sr.cs_warehouse_sk = i1.inv_warehouse_sk
     AND sr.cs_item_sk = i1.inv_item_sk
    JOIN inventory i2
      ON (sr.cs_sold_date_sk - 365) = i2.inv_date_sk
     AND sr.cs_warehouse_sk = i2.inv_warehouse_sk
     AND sr.cs_item_sk = i2.inv_item_sk
    JOIN warehouse w
      ON sr.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
      ON sr.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE EXISTS (
          SELECT 1
          FROM catalog_returns cr3
          JOIN reason r3 ON cr3.cr_reason_sk = r3.r_reason_sk
          WHERE cr3.cr_order_number = sr.cs_order_number
            AND r3.r_reason_desc = 'Damaged'
        )
    UNION ALL
    SELECT
      smtr.sales_year                    AS year,
      CAST(NULL AS integer)             AS current_qty,
      CAST(NULL AS integer)             AS past_qty,
      CAST(NULL AS varchar)             AS warehouse_name,
      CAST(NULL AS varchar)             AS ship_mode_code,
      smtr.store_name                   AS store_name,
      smtr.store_net_paid               AS total_sales,
      smtr.store_net_profit             AS total_profit,
      CAST(0.0 AS decimal(7,2))          AS total_returns
    FROM store_metrics smtr
  )
SELECT
  grouping_id,
  year,
  warehouse_name,
  ship_mode_code,
  store_name,
  total_sales,
  total_profit,
  total_returns,
  rn
FROM (
  SELECT
    GROUPING(year, warehouse_name, ship_mode_code, store_name) AS grouping_id,
    year,
    warehouse_name,
    ship_mode_code,
    store_name,
    SUM(total_sales)   AS total_sales,
    SUM(total_profit)  AS total_profit,
    SUM(total_returns) AS total_returns,
    ROW_NUMBER() OVER (PARTITION BY GROUPING(year, warehouse_name, ship_mode_code, store_name)
                       ORDER BY SUM(total_sales) DESC) AS rn
  FROM base
  GROUP BY GROUPING SETS (
      (year, warehouse_name, ship_mode_code),
      (year, store_name)
    )
) q
WHERE rn <= 5
ORDER BY grouping_id, total_sales DESC
LIMIT 100
