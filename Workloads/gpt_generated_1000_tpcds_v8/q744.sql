WITH
  /* Base sales with required joins and initial string filters */
  base_sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_warehouse_sk,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      ws.ws_promo_sk,
      p.p_discount_active,
      d.d_year,
      w.w_state,
      w.w_city,
      ca.ca_street_name,
      ca.ca_city
    FROM web_sales ws
    JOIN date_dim d          ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(ca.ca_street_name, '^P.*')       -- street names beginning with "P"
      AND ca.ca_city LIKE 'A%'                       -- city names starting with "A"
  ),

  /* Warehouse keys to be excluded – built with EXCEPT */
  exclude_warehouses AS (
    SELECT w_warehouse_sk FROM warehouse WHERE w_city LIKE 'B%'
    EXCEPT
    SELECT w_warehouse_sk FROM warehouse WHERE w_state = 'TX'
  ),

  /* Aggregated results from two different promotion‑discount states */
  aggregated AS (
    SELECT
      bs.w_state,
      bs.d_year,
      regexp_extract(bs.ca_street_name, '^([^ ]+)', 1) AS street_prefix,
      SUM(bs.ws_ext_sales_price) AS total_sales,
      SUM(bs.ws_net_profit)       AS total_profit,
      CASE WHEN SUM(bs.ws_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
      COUNT(DISTINCT bs.ws_order_number) AS orders_cnt
    FROM base_sales bs
    WHERE bs.ws_warehouse_sk NOT IN (SELECT w_warehouse_sk FROM exclude_warehouses)
      AND EXISTS (
        SELECT 1 FROM inventory i
        WHERE i.inv_date_sk = bs.ws_sold_date_sk
          AND i.inv_warehouse_sk = bs.ws_warehouse_sk
          AND i.inv_quantity_on_hand > 0
      )
      AND bs.p_discount_active = 'Y'
      AND regexp_like(bs.ca_street_name, '^P.*')
    GROUP BY
      bs.w_state,
      bs.d_year,
      regexp_extract(bs.ca_street_name, '^([^ ]+)', 1)

    UNION

    SELECT
      bs.w_state,
      bs.d_year,
      regexp_extract(bs.ca_street_name, '^([^ ]+)', 1) AS street_prefix,
      SUM(bs.ws_ext_sales_price) AS total_sales,
      SUM(bs.ws_net_profit)       AS total_profit,
      CASE WHEN SUM(bs.ws_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
      COUNT(DISTINCT bs.ws_order_number) AS orders_cnt
    FROM base_sales bs
    WHERE bs.ws_warehouse_sk NOT IN (SELECT w_warehouse_sk FROM exclude_warehouses)
      AND EXISTS (
        SELECT 1 FROM inventory i
        WHERE i.inv_date_sk = bs.ws_sold_date_sk
          AND i.inv_warehouse_sk = bs.ws_warehouse_sk
          AND i.inv_quantity_on_hand > 0
      )
      AND bs.p_discount_active = 'N'
      AND bs.ca_street_name LIKE '%Lane%'
    GROUP BY
      bs.w_state,
      bs.d_year,
      regexp_extract(bs.ca_street_name, '^([^ ]+)', 1)
  )

SELECT
  w_state,
  d_year,
  street_prefix,
  total_sales,
  total_profit,
  profit_flag,
  orders_cnt,
  ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
FROM aggregated
ORDER BY total_sales DESC
