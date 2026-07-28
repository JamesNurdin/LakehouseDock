WITH
  store_agg AS (
    SELECT
      ss_item_sk,
      ss_customer_sk,
      ss_sold_date_sk,
      SUM(ss_ext_sales_price) AS total_store_sales,
      SUM(ss_net_profit)      AS total_store_profit,
      COUNT(*)                AS cnt_store_sales
    FROM store_sales
    WHERE ss_quantity > 2
    GROUP BY ss_item_sk, ss_customer_sk, ss_sold_date_sk
  ),
  web_agg AS (
    SELECT
      ws_item_sk,
      ws_bill_customer_sk,
      ws_sold_date_sk,
      SUM(ws_ext_sales_price) AS total_web_sales,
      SUM(ws_net_profit)      AS total_web_profit,
      COUNT(*)                AS cnt_web_sales
    FROM web_sales
    WHERE ws_quantity > 1
    GROUP BY ws_item_sk, ws_bill_customer_sk, ws_sold_date_sk
  )
SELECT
  agg.d_year,
  agg.i_brand,
  agg.c_customer_id,
  agg.distinct_items_sold,
  agg.store_sales_sum,
  agg.web_sales_sum,
  agg.total_return_amount,
  CASE
    WHEN agg.total_profit > 10000 THEN 'HighProfit'
    ELSE 'LowProfit'
  END AS profit_category
FROM (
  SELECT
    d.d_year,
    i.i_brand,
    c.c_customer_id,
    COUNT(DISTINCT s.ss_item_sk)                                 AS distinct_items_sold,
    SUM(s.total_store_sales)                                      AS store_sales_sum,
    SUM(w.total_web_sales)                                        AS web_sales_sum,
    SUM(CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_return_amt ELSE 0 END) AS total_return_amount,
    SUM(s.total_store_profit) + SUM(w.total_web_profit)          AS total_profit
  FROM store_agg s
  JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
  JOIN item i ON s.ss_item_sk = i.i_item_sk
  LEFT JOIN web_agg w
    ON w.ws_item_sk = i.i_item_sk
   AND w.ws_bill_customer_sk = c.c_customer_sk
   AND w.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE
    d.d_year = 1999
    AND i.i_brand = 'Brand#12'
    AND c.c_birth_year BETWEEN 1960 AND 1965
    AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_item_sk = i.i_item_sk
            AND ws.ws_ext_discount_amt > 5.00
          LIMIT 1
        )
  GROUP BY
    d.d_year,
    i.i_brand,
    c.c_customer_id
  HAVING
    SUM(s.total_store_sales) > 5000
) agg
ORDER BY agg.store_sales_sum DESC
LIMIT 100
