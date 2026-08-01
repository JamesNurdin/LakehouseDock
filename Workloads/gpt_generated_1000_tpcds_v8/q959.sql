WITH returns_sample AS (
    SELECT cr_returned_date_sk,
           cr_item_sk,
           cr_return_amount
    FROM catalog_returns TABLESAMPLE BERNOULLI (10)
    WHERE cr_return_amount > 100
),
sales_sample AS (
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_ext_sales_price
    FROM web_sales TABLESAMPLE BERNOULLI (10)
    WHERE ws_ext_sales_price > 100
),
common_keys AS (
    SELECT d.d_year,
           i.i_category
    FROM returns_sample r
    JOIN date_dim d ON r.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON r.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
    INTERSECT
    SELECT d.d_year,
           i.i_category
    FROM sales_sample s
    JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
),
return_agg AS (
    SELECT d.d_year,
           i.i_category,
           SUM(r.cr_return_amount) AS total_return_amount
    FROM returns_sample r
    JOIN date_dim d ON r.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON r.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
),
sales_agg AS (
    SELECT d.d_year,
           i.i_category,
           SUM(s.ws_ext_sales_price) AS total_sales_amount
    FROM sales_sample s
    JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
)
SELECT ck.d_year AS year,
       ck.i_category AS category,
       COALESCE(r.total_return_amount, 0) AS total_return_amount,
       COALESCE(s.total_sales_amount, 0) AS total_sales_amount
FROM common_keys ck
LEFT JOIN return_agg r
  ON ck.d_year = r.d_year AND ck.i_category = r.i_category
LEFT JOIN sales_agg s
  ON ck.d_year = s.d_year AND ck.i_category = s.i_category
UNION
SELECT d.d_year AS year,
       i.i_category AS category,
       SUM(r.cr_return_amount) AS total_return_amount,
       SUM(s.ws_ext_sales_price) AS total_sales_amount
FROM returns_sample r
JOIN sales_sample s
  ON r.cr_item_sk = s.ws_item_sk
JOIN date_dim d ON r.cr_returned_date_sk = d.d_date_sk
JOIN item i ON r.cr_item_sk = i.i_item_sk
GROUP BY d.d_year, i.i_category
ORDER BY year DESC, category
OFFSET 0 FETCH NEXT 100 ROWS ONLY
