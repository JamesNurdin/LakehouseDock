WITH
  high_store_profit AS (
    SELECT
      d.d_year,
      c.c_customer_id,
      SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    RIGHT OUTER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_item_sk IN (
          SELECT cs.cs_item_sk
          FROM catalog_sales cs
          WHERE cs.cs_quantity > 5
        )
      AND ss.ss_net_profit > (
          SELECT AVG(cs2.cs_net_profit)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = 2450
        )
    GROUP BY d.d_year, c.c_customer_id
    HAVING SUM(ss.ss_net_profit) > 10000
  ),
  high_catalog_profit AS (
    SELECT
      d.d_year,
      c.c_customer_id,
      SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_item_sk IN (
          SELECT ss2.ss_item_sk
          FROM store_sales ss2
          WHERE ss2.ss_quantity > 5
        )
    GROUP BY d.d_year, c.c_customer_id
    HAVING SUM(cs.cs_net_profit) > 10000
  )
SELECT *
FROM high_store_profit
EXCEPT
SELECT *
FROM high_catalog_profit
ORDER BY d_year DESC, total_profit DESC
LIMIT 100
