WITH base AS (
  SELECT
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    cs.cs_order_number,
    d_sold.d_year AS sold_year,
    i.i_brand,
    sr.sr_return_amt,
    wr.wr_return_ship_cost,
    cs.cs_item_sk
  FROM catalog_sales cs
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
  JOIN date_dim d_returned
    ON sr.sr_returned_date_sk = d_returned.d_date_sk
  JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
  JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
  WHERE d_sold.d_year = 2001
    AND i.i_manufact_id IN (220, 86)
    AND p.p_cost > 500
    AND cs.cs_quantity > 2
    AND sr.sr_return_amt > 0
    AND wr.wr_return_ship_cost > 20
)
SELECT
  sold_year,
  i_brand,
  profit_flag,
  SUM(cs_ext_sales_price) AS total_sales,
  COUNT(DISTINCT cs_order_number) AS order_cnt,
  AVG(cs_net_profit) AS avg_profit,
  MIN(sr_return_amt) AS min_return_amt,
  MAX(wr_return_ship_cost) AS max_ship_cost
FROM (
  SELECT
    *,
    CASE WHEN cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
  FROM base b
  WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = b.cs_item_sk
      AND wr2.wr_return_quantity > 10
  )
) t
GROUP BY sold_year, i_brand, profit_flag
ORDER BY total_sales DESC
LIMIT 100
