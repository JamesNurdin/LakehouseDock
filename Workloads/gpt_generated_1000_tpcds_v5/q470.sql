WITH base AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_tax_percentage,
    i.i_category,
    d_sold.d_year,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    wr.wr_return_amt,
    inv.inv_quantity_on_hand
  FROM catalog_sales cs
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_sold.d_date_sk
  LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d_sold.d_date_sk
  WHERE cc.cc_tax_percentage BETWEEN 0.02 AND 0.12
    AND d_sold.d_year BETWEEN 1999 AND 2001
    AND i.i_current_price > 50
),
agg AS (
  SELECT
    cc_call_center_id,
    i_category,
    d_year,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    SUM(COALESCE(wr_return_amt, 0)) AS total_returns,
    SUM(inv_quantity_on_hand) AS total_on_hand
  FROM base
  GROUP BY cc_call_center_id, i_category, d_year
)
SELECT
  a.cc_call_center_id,
  a.i_category,
  a.d_year,
  a.total_sales,
  a.total_profit,
  a.total_returns,
  a.total_on_hand,
  a.total_profit / NULLIF(a.total_sales, 0) AS profit_margin,
  (SELECT AVG(total_profit) FROM agg) AS avg_profit_all
FROM agg a
WHERE a.total_sales > 100000
  AND a.total_returns > 5000
  AND a.total_profit / NULLIF(a.total_sales, 0) > 0.05
ORDER BY a.total_profit DESC
LIMIT 100
