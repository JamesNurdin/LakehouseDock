WITH
  key_intersect AS (
    SELECT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_purpose = 'Unknown'
    INTERSECT
    SELECT ws.ws_item_sk
    FROM web_sales ws
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    WHERE p2.p_purpose = 'Unknown'
  ),
  key_except AS (
    SELECT ss.ss_customer_sk AS cust_sk
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
    EXCEPT
    SELECT ws.ws_bill_customer_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
  ),
  store_year_profit AS (
    SELECT
      d.d_year AS year,
      SUM(ss.ss_net_profit) AS store_profit,
      CAST(NULL AS double) AS web_profit
    FROM store_sales ss
    RIGHT OUTER JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
      AND ss.ss_item_sk IN (SELECT item_sk FROM key_intersect)
      AND ss.ss_customer_sk IN (SELECT cust_sk FROM key_except)
    GROUP BY d.d_year
    HAVING SUM(ss.ss_net_profit) > 1000
  ),
  web_year_profit AS (
    SELECT
      COALESCE(d_s.d_year, d_w.d_year) AS year,
      CAST(NULL AS double) AS store_profit,
      SUM(COALESCE(ws.ws_net_profit, 0)) AS web_profit
    FROM store_sales ss
    FULL OUTER JOIN web_sales ws
      ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
    LEFT JOIN date_dim d_s
      ON ss.ss_sold_date_sk = d_s.d_date_sk
    LEFT JOIN date_dim d_w
      ON ws.ws_sold_date_sk = d_w.d_date_sk
    WHERE (
            ss.ss_item_sk IN (SELECT item_sk FROM key_intersect)
         OR ws.ws_item_sk IN (SELECT item_sk FROM key_intersect)
          )
    GROUP BY COALESCE(d_s.d_year, d_w.d_year)
    HAVING SUM(COALESCE(ws.ws_net_profit, 0)) > 500
  )
SELECT year, store_profit, web_profit
FROM store_year_profit
UNION
SELECT year, store_profit, web_profit
FROM web_year_profit
ORDER BY year DESC
LIMIT 100
