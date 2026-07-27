WITH sales_by_ship AS (
  SELECT
    cs.cs_order_number AS cs_order_number,
    c.c_customer_id AS c_customer_id,
    SUM(cs.cs_ext_sales_price) AS sales_amount,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    'ShipMode' AS source
  FROM catalog_sales cs
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE sm.sm_contract = 'I3uCelXtjP'
    AND cs.cs_quantity > 2
  GROUP BY cs.cs_order_number, c.c_customer_id
),
sales_by_promo AS (
  SELECT
    cs.cs_order_number AS cs_order_number,
    c.c_customer_id AS c_customer_id,
    SUM(cs.cs_ext_sales_price) AS sales_amount,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    'Promotion' AS source
  FROM catalog_sales cs
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer c
    ON cs.cs_ship_customer_sk = c.c_customer_sk
  WHERE p.p_response_target = 1
    AND cs.cs_list_price > 150
  GROUP BY cs.cs_order_number, c.c_customer_id
)
SELECT
  cs_order_number,
  c_customer_id,
  sales_amount,
  profit_flag,
  source
FROM sales_by_ship
UNION ALL
SELECT
  cs_order_number,
  c_customer_id,
  sales_amount,
  profit_flag,
  source
FROM sales_by_promo
LIMIT 100
