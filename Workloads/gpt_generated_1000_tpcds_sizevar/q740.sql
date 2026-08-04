WITH
  sales_agg AS (
    SELECT
      ws.ws_item_sk,
      d.d_year,
      SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_brand = 'BrandA'
    GROUP BY ws.ws_item_sk, d.d_year
  ),
  sales_rank AS (
    SELECT
      ws_item_sk,
      d_year,
      total_sales,
      RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM sales_agg
  ),
  returns_agg AS (
    SELECT
      wr.wr_item_sk,
      d.d_year,
      SUM(wr.wr_return_amt) AS total_returns
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'BrandA')
    GROUP BY wr.wr_item_sk, d.d_year
  ),
  returns_rank AS (
    SELECT
      wr_item_sk,
      d_year,
      total_returns,
      RANK() OVER (PARTITION BY d_year ORDER BY total_returns DESC) AS return_rank
    FROM returns_agg
  ),
  top_sales AS (
    SELECT ws_item_sk AS item_sk, d_year, total_sales
    FROM sales_rank
    WHERE sales_rank <= 5
  ),
  top_returns AS (
    SELECT wr_item_sk AS item_sk, d_year, total_returns
    FROM returns_rank
    WHERE return_rank <= 5
  ),
  intersect_items AS (
    SELECT item_sk, d_year
    FROM top_sales
    INTERSECT
    SELECT item_sk, d_year
    FROM top_returns
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  ii.d_year,
  ts.total_sales,
  tr.total_returns,
  CASE WHEN ts.total_sales > tr.total_returns THEN 'Profit' ELSE 'Loss' END AS profit_category
FROM intersect_items ii
JOIN top_sales ts ON ii.item_sk = ts.item_sk AND ii.d_year = ts.d_year
JOIN top_returns tr ON ii.item_sk = tr.item_sk AND ii.d_year = tr.d_year
JOIN item i ON i.i_item_sk = ii.item_sk
ORDER BY ts.total_sales DESC
LIMIT 100
