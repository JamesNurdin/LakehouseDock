WITH high_spenders AS (
    SELECT c.c_customer_sk,
           SUM(ss.ss_net_paid) AS total_spent
    FROM store_sales ss
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
    HAVING SUM(ss.ss_net_paid) > 5000
)
SELECT cat,
       total_profit,
       source
FROM (
    SELECT i.i_category AS cat,
           SUM(ss.ss_net_profit) AS total_profit,
           'store' AS source
    FROM store_sales ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN high_spenders hs
      ON ss.ss_customer_sk = hs.c_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450200
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_return_time_sk = ss.ss_sold_time_sk
      )
    GROUP BY i.i_category
    HAVING SUM(ss.ss_net_profit) > (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
        WHERE i2.i_category = i.i_category
    )
    UNION ALL
    SELECT i.i_category AS cat,
           SUM(cs.cs_net_profit) AS total_profit,
           'catalog' AS source
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN high_spenders hs
      ON cs.cs_bill_customer_sk = hs.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450200
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_item_sk = cs.cs_item_sk
            AND wr.wr_returned_time_sk = cs.cs_sold_time_sk
      )
    GROUP BY i.i_category
    HAVING SUM(cs.cs_net_profit) > (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
        WHERE i2.i_category = i.i_category
    )
) t
ORDER BY total_profit DESC
LIMIT 100
