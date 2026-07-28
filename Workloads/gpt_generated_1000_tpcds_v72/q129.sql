WITH
  sales_agg AS (
    SELECT
      cs_item_sk,
      cs_call_center_sk,
      cs_sold_date_sk,
      cs_catalog_page_sk,
      cs_order_number,
      SUM(cs_net_profit)   AS total_profit,
      SUM(cs_quantity)    AS total_quantity
    FROM tpcds.catalog_sales
    GROUP BY cs_item_sk, cs_call_center_sk, cs_sold_date_sk, cs_catalog_page_sk, cs_order_number
  ),

  returns_agg AS (
    SELECT
      item_sk,
      SUM(return_amt) AS total_return_amount
    FROM (
      SELECT cr_item_sk AS item_sk, cr_return_amount AS return_amt
      FROM tpcds.catalog_returns
      UNION ALL
      SELECT wr_item_sk AS item_sk, wr_return_amt AS return_amt
      FROM tpcds.web_returns
    ) r
    GROUP BY item_sk
  ),

  distinct_sales AS (
    SELECT
      cc.cc_name,
      i.i_item_id,
      i.i_product_name,
      cp.cp_description,
      dd.d_year,
      sa.total_profit,
      sa.total_quantity,
      ra.total_return_amount,
      (
        SELECT AVG(cs_net_profit)
        FROM tpcds.catalog_sales cs3
        WHERE cs3.cs_item_sk = i.i_item_sk
      ) AS avg_item_profit,
      ib.ib_upper_bound
    FROM sales_agg sa
    JOIN tpcds.call_center cc
      ON sa.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
      ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.item i
      ON sa.cs_item_sk = i.i_item_sk
    JOIN tpcds.date_dim dd
      ON sa.cs_sold_date_sk = dd.d_date_sk
    LEFT JOIN returns_agg ra
      ON ra.item_sk = i.i_item_sk
    LEFT JOIN tpcds.catalog_returns cr
      ON cr.cr_item_sk = i.i_item_sk
     AND cr.cr_order_number = sa.cs_order_number
    LEFT JOIN tpcds.household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN tpcds.income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE dd.d_year = 2001
      AND i.i_brand_id IN (1, 2, 3)
      AND ib.ib_lower_bound >= 60000
  )
SELECT
  cc_name,
  i_item_id,
  i_product_name,
  d_year,
  total_profit,
  total_quantity,
  total_return_amount,
  avg_item_profit,
  ib_upper_bound,
  RANK() OVER (PARTITION BY cc_name ORDER BY total_profit DESC) AS profit_rank
FROM (
  SELECT DISTINCT * FROM distinct_sales
) ds
ORDER BY profit_rank ASC, total_profit DESC
LIMIT 100
