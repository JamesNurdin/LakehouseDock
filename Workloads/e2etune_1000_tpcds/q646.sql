WITH sales_agg AS (
   SELECT cs_item_sk AS item_sk,
          cs_sold_date_sk AS date_sk,
          SUM(cs_ext_sales_price) AS total_sales,
          SUM(cs_net_profit) AS total_profit,
          SUM(cs_quantity) AS total_quantity,
          SUM(cs_coupon_amt) AS total_coupon
   FROM catalog_sales
   WHERE cs_quantity > 50
     AND cs_coupon_amt > 0
   GROUP BY cs_item_sk, cs_sold_date_sk
),
store_ret_agg AS (
   SELECT sr_item_sk AS item_sk,
          sr_returned_date_sk AS date_sk,
          SUM(sr_return_amt) AS store_return_amt,
          SUM(sr_return_quantity) AS store_return_qty,
          SUM(sr_net_loss) AS store_net_loss
   FROM store_returns
   WHERE sr_return_quantity > 0
   GROUP BY sr_item_sk, sr_returned_date_sk
),
web_ret_agg AS (
   SELECT wr_item_sk AS item_sk,
          wr_returned_date_sk AS date_sk,
          SUM(wr_return_amt) AS web_return_amt,
          SUM(wr_return_quantity) AS web_return_qty,
          SUM(wr_net_loss) AS web_net_loss
   FROM web_returns
   WHERE wr_return_quantity > 0
   GROUP BY wr_item_sk, wr_returned_date_sk
)
SELECT s.item_sk,
       s.date_sk,
       s.total_sales,
       s.total_profit,
       COALESCE(sr.store_return_amt, 0) + COALESCE(wr.web_return_amt, 0) AS total_return_amt,
       COALESCE(sr.store_return_qty, 0) + COALESCE(wr.web_return_qty, 0) AS total_return_qty,
       s.total_profit - (COALESCE(sr.store_net_loss, 0) + COALESCE(wr.web_net_loss, 0)) AS net_contribution,
       CASE WHEN s.total_quantity > 0 THEN
            (COALESCE(sr.store_return_qty, 0) + COALESCE(wr.web_return_qty, 0)) / s.total_quantity
            ELSE 0 END AS return_qty_ratio,
       RANK() OVER (ORDER BY s.total_profit - (COALESCE(sr.store_net_loss, 0) + COALESCE(wr.web_net_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN store_ret_agg sr
  ON s.item_sk = sr.item_sk AND s.date_sk = sr.date_sk
LEFT JOIN web_ret_agg wr
  ON s.item_sk = wr.item_sk AND s.date_sk = wr.date_sk
WHERE (s.total_sales > 10000 OR (COALESCE(sr.store_return_amt, 0) + COALESCE(wr.web_return_amt, 0)) > 5000)
ORDER BY net_contribution DESC
LIMIT 100
