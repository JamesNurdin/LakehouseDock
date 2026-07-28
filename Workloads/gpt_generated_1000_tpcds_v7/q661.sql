WITH
  filtered AS (
    SELECT
      cs.cs_order_number,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cs.cs_sold_date_sk,
      cs.cs_item_sk,
      cs.cs_call_center_sk,
      i.i_brand,
      i.i_category_id,
      d_sold.d_year,
      d_sold.d_month_seq,
      cc.cc_name,
      cc.cc_state,
      sr.sr_return_amt,
      sr.sr_store_sk,
      d_ret.d_year AS ret_year,
      d_ret.d_month_seq AS ret_month_seq,
      s.s_store_name,
      s.s_state
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d_ret
      ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    WHERE cs.cs_ext_sales_price > 1000
      AND d_sold.d_year = 2001
      AND i.i_category_id IN (4, 10)
      AND cc.cc_state = 'CA'
      AND s.s_state = 'CA'
      AND sr.sr_return_amt > 0
  ),
  agg AS (
    SELECT
      cc_name,
      d_year,
      d_month_seq,
      i_brand,
      SUM(cs_ext_sales_price) AS total_sales,
      SUM(cs_net_profit) AS total_profit,
      COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM filtered
    GROUP BY cc_name, d_year, d_month_seq, i_brand
  )
SELECT
  cc_name,
  d_year,
  i_brand,
  total_sales,
  total_profit,
  order_cnt,
  RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
  AVG(total_sales) OVER (
    PARTITION BY cc_name
    ORDER BY d_month_seq
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS moving_avg_3m
FROM agg
ORDER BY total_sales DESC
LIMIT 20
