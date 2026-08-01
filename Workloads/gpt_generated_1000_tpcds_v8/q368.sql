/* Goal: Analyze web sales performance by year, gender, website and catalog department, combining sales and return metrics, pricing arrays, and handling unmatched records, while demonstrating complex joins, set operations, anti‑joins and grouping sets. */
WITH
  /* Pre‑aggregate sales by order */
  ws_agg AS (
    SELECT
      ws_order_number,
      SUM(ws_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt
    FROM
      web_sales
    WHERE
      ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001
      )
    GROUP BY
      ws_order_number
  ),
  /* Pre‑aggregate returns by order */
  wr_agg AS (
    SELECT
      wr_order_number,
      SUM(wr_return_amt) AS total_return,
      COUNT(*) AS return_cnt
    FROM
      web_returns
    GROUP BY
      wr_order_number
  ),
  /* Build an array of two price measures per row */
  price_expand AS (
    SELECT
      ws_order_number,
      ws_item_sk,
      ARRAY[ws_list_price, ws_ext_sales_price] AS price_array
    FROM
      web_sales
  ),
  /* Two year‑specific extracts to be UNION‑ed */
  sales_2001 AS (
    SELECT
      ws_order_number,
      ws_item_sk,
      ws_sold_date_sk,
      ws_web_site_sk,
      ws_bill_cdemo_sk
    FROM
      web_sales ws
      JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001
  ),
  sales_2002 AS (
    SELECT
      ws_order_number,
      ws_item_sk,
      ws_sold_date_sk,
      ws_web_site_sk,
      ws_bill_cdemo_sk
    FROM
      web_sales ws
      JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2002
  ),
  sales_union AS (
    SELECT * FROM sales_2001
    UNION ALL
    SELECT * FROM sales_2002
  ),
  /* Join price array with the unioned sales rows */
  joined AS (
    SELECT
      pe.ws_order_number,
      pe.ws_item_sk,
      pe.price_array,
      su.ws_sold_date_sk,
      su.ws_web_site_sk,
      su.ws_bill_cdemo_sk
    FROM
      price_expand pe
      JOIN sales_union su ON pe.ws_order_number = su.ws_order_number
        AND pe.ws_item_sk = su.ws_item_sk
  )
SELECT
  DISTINCT
  d.d_year,
  cd.cd_gender,
  wsite.web_site_sk,
  cp.cp_department,
  SUM(wa.total_sales)            AS sum_sales,
  SUM(wr.total_return)          AS sum_return,
  SUM(price)                     AS sum_price_array,
  COUNT(*)                       AS cnt_rows
FROM
  joined j
  JOIN ws_agg wa ON j.ws_order_number = wa.ws_order_number
  LEFT JOIN wr_agg wr ON j.ws_order_number = wr.wr_order_number
  JOIN date_dim d ON j.ws_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON j.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
  FULL OUTER JOIN web_site wsite ON j.ws_web_site_sk = wsite.web_site_sk
  JOIN web_site wsite_open ON wsite_open.web_open_date_sk = d.d_date_sk
  LEFT JOIN UNNEST(j.price_array) AS t(price) ON TRUE
WHERE
  NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_order_number = j.ws_order_number
      AND wr2.wr_return_amt > 1000
  )
GROUP BY
  GROUPING SETS (
    (d.d_year, cd.cd_gender, wsite.web_site_sk, cp.cp_department),
    (d.d_year, cd.cd_gender, wsite.web_site_sk),
    (d.d_year, cd.cd_gender),
    ()
  )
HAVING
  SUM(wa.total_sales) > 0
ORDER BY
  sum_sales DESC
LIMIT 100
