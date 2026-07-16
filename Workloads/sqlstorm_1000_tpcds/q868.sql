WITH date_filtered AS (
   SELECT d_date_sk, d_year
   FROM date_dim
   WHERE d_year = 1999
), sales AS (
   SELECT ss_sold_date_sk AS date_sk, ss_item_sk AS item_sk, ss_ext_sales_price AS ext_sales_price, ss_net_profit AS net_profit
   FROM store_sales
   UNION ALL
   SELECT ws_sold_date_sk, ws_item_sk, ws_ext_sales_price, ws_net_profit
   FROM web_sales
   UNION ALL
   SELECT cs_sold_date_sk, cs_item_sk, cs_ext_sales_price, cs_net_profit
   FROM catalog_sales
), ret AS (
   SELECT cr_returned_date_sk AS date_sk, cr_item_sk AS item_sk, cr_return_amt_inc_tax AS ext_return_price, cr_net_loss AS net_loss
   FROM catalog_returns
   UNION ALL
   SELECT sr_returned_date_sk, sr_item_sk, sr_return_amt_inc_tax, sr_net_loss
   FROM store_returns
   UNION ALL
   SELECT wr_returned_date_sk, wr_item_sk, wr_return_amt_inc_tax, wr_net_loss
   FROM web_returns
)
SELECT df.d_year,
       i.i_category,
       i.i_brand,
       SUM(s.ext_sales_price) AS total_sales,
       SUM(s.net_profit) AS total_profit,
       SUM(COALESCE(r.ext_return_price, 0)) AS total_returns,
       SUM(COALESCE(r.net_loss, 0)) AS total_return_loss
FROM date_filtered df
JOIN sales s ON s.date_sk = df.d_date_sk
JOIN item i ON i.i_item_sk = s.item_sk
LEFT JOIN ret r ON r.date_sk = df.d_date_sk AND r.item_sk = i.i_item_sk
GROUP BY df.d_year, i.i_category, i.i_brand
ORDER BY df.d_year, i.i_category, i.i_brand
