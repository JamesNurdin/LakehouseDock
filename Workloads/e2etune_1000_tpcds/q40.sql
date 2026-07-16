WITH sales_agg AS (
  SELECT
    ss_item_sk AS item_sk,
    ss_sold_date_sk AS date_sk,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_quantity) AS total_qty,
    AVG(ss_sales_price) AS avg_price
  FROM store_sales
  WHERE ss_ext_discount_amt > 0
  GROUP BY ss_item_sk, ss_sold_date_sk
),
returns_agg AS (
  SELECT
    cr_item_sk AS item_sk,
    cr_returned_date_sk AS date_sk,
    SUM(cr_return_amount) AS total_returns,
    SUM(cr_return_quantity) AS total_return_qty,
    AVG(cr_fee) AS avg_fee
  FROM catalog_returns
  WHERE cr_fee > 20
  GROUP BY cr_item_sk, cr_returned_date_sk
)
SELECT
  s.item_sk,
  s.date_sk,
  s.total_sales,
  r.total_returns,
  CASE WHEN s.total_sales > 0 THEN r.total_returns / s.total_sales ELSE NULL END AS return_to_sales_ratio,
  s.avg_price,
  r.avg_fee,
  RANK() OVER (ORDER BY CASE WHEN s.total_sales > 0 THEN r.total_returns / s.total_sales ELSE NULL END DESC) AS ratio_rank
FROM sales_agg s
JOIN returns_agg r
  ON s.item_sk = r.item_sk
 AND s.date_sk = r.date_sk
WHERE s.total_sales > 1000
ORDER BY return_to_sales_ratio DESC
LIMIT 100
