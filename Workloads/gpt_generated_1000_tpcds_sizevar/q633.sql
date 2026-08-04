WITH
  warehouse_set AS (
    SELECT w_warehouse_sk
    FROM tpcds.warehouse
    WHERE w_county = 'Mobile County'
    EXCEPT
    SELECT w_warehouse_sk
    FROM tpcds.warehouse
    WHERE w_state = 'CA'
  ),
  agg_sales AS (
    SELECT
      cs_warehouse_sk,
      cs_sold_time_sk,
      SUM(cs_ext_sales_price)      AS total_sales,
      SUM(cs_quantity)            AS total_qty,
      COUNT(*)                    AS order_cnt,
      AVG(cs_sales_price)         AS avg_price,
      MIN(cs_sales_price)         AS min_price,
      MAX(cs_sales_price)         AS max_price
    FROM tpcds.catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_sales_price > 20
      AND cs_coupon_amt < 2000
      AND cs_quantity >= 2
      AND cs_warehouse_sk IS NOT NULL
    GROUP BY cs_warehouse_sk, cs_sold_time_sk
  )
SELECT
  w.w_warehouse_id,
  w.w_county,
  w.w_state,
  t.t_shift,
  t.t_minute,
  agg.total_sales,
  agg.total_qty,
  agg.order_cnt,
  agg.avg_price,
  agg.min_price,
  agg.max_price,
  ld.total_discount
FROM agg_sales agg
JOIN tpcds.time_dim t
  ON agg.cs_sold_time_sk = t.t_time_sk
FULL OUTER JOIN tpcds.warehouse w
  ON agg.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN warehouse_set ws
  ON w.w_warehouse_sk = ws.w_warehouse_sk
CROSS JOIN LATERAL (
  SELECT SUM(cs_ext_discount_amt) AS total_discount
  FROM tpcds.catalog_sales cs
  WHERE cs.cs_warehouse_sk = w.w_warehouse_sk
    AND cs.cs_sold_time_sk = agg.cs_sold_time_sk
) ld
WHERE (
        w.w_county = 'Mobile County'
        OR w.w_county = 'Bronx County'
      )
  AND w.w_state = 'TX'
  AND t.t_shift = 'first'
  AND t.t_minute BETWEEN 10 AND 30
  AND ws.w_warehouse_sk IS NOT NULL
  AND agg.avg_price > 25
ORDER BY agg.total_sales DESC
LIMIT 100
