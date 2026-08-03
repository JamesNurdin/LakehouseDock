WITH
  avg_sales AS (
    SELECT avg(cs_ext_sales_price) AS avg_ext_sales_price
    FROM catalog_sales
  ),
  billing_sales AS (
    SELECT
      c.c_customer_id,
      cs.cs_promo_sk,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_indicator,
      (SELECT avg_ext_sales_price FROM avg_sales) AS avg_sales_price
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_sales_price > 5000
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
          AND cs2.cs_net_profit > 1000
      )
    GROUP BY CUBE (c.c_customer_id, cs.cs_promo_sk)
  ),
  shipping_sales AS (
    SELECT
      c.c_customer_id,
      cs.cs_promo_sk,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_indicator,
      (SELECT avg_ext_sales_price FROM avg_sales) AS avg_sales_price
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_ship_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_sales_price > 5000
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_ship_customer_sk = c.c_customer_sk
          AND cs2.cs_net_profit > 1000
      )
    GROUP BY CUBE (c.c_customer_id, cs.cs_promo_sk)
  )
SELECT
  c_customer_id,
  cs_promo_sk,
  total_sales,
  total_profit,
  profit_indicator,
  avg_sales_price
FROM billing_sales
UNION ALL
SELECT
  c_customer_id,
  cs_promo_sk,
  total_sales,
  total_profit,
  profit_indicator,
  avg_sales_price
FROM shipping_sales
LIMIT 100
