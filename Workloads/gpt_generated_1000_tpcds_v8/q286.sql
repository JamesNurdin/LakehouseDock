WITH
  promo_info AS (
    SELECT
      p_promo_sk,
      regexp_extract(p_promo_name, '(\\d+)', 1) AS promo_code,
      p_channel_demo
    FROM promotion
    WHERE regexp_like(p_promo_name, '[A-Za-z]+\\d+')
  ),
  sales_data AS (
    SELECT
      cs.cs_warehouse_sk,
      cs.cs_promo_sk,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cs.cs_quantity,
      cs.cs_order_number,
      ca.ca_city,
      pi.promo_code
    FROM catalog_sales cs
    LEFT JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN promo_info pi
      ON cs.cs_promo_sk = pi.p_promo_sk
  )
SELECT
  CONCAT(
    COALESCE(w.w_warehouse_name, 'UNKNOWN_WAREHOUSE'),
    ' - ',
    COALESCE(sd.promo_code, 'NO_PROMO')
  ) AS warehouse_promo,
  SUM(sd.cs_ext_sales_price) AS total_sales,
  SUM(sd.cs_net_profit) AS total_profit,
  COUNT(*) AS sale_rows
FROM (
  SELECT
    cs_warehouse_sk,
    cs_promo_sk,
    cs_ext_sales_price,
    cs_net_profit,
    cs_quantity,
    cs_order_number,
    ca_city,
    promo_code
  FROM sales_data
  WHERE ca_city LIKE 'S%'
    AND regexp_like(ca_city, 'ville$')
  UNION DISTINCT
  SELECT
    cs_warehouse_sk,
    cs_promo_sk,
    cs_ext_sales_price,
    cs_net_profit,
    cs_quantity,
    cs_order_number,
    ca_city,
    promo_code
  FROM sales_data
  WHERE ca_city NOT LIKE 'S%'
) sd
FULL OUTER JOIN warehouse w
  ON sd.cs_warehouse_sk = w.w_warehouse_sk
GROUP BY
  CONCAT(
    COALESCE(w.w_warehouse_name, 'UNKNOWN_WAREHOUSE'),
    ' - ',
    COALESCE(sd.promo_code, 'NO_PROMO')
  )
ORDER BY total_sales DESC
LIMIT 100
