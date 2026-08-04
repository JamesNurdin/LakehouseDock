WITH
  /* Sample a fraction of store_sales */
  store_sales_sampled AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (5)
    WHERE ss_ext_sales_price > 2000
  ),
  /* Aggregate the sampled store sales */
  ss_agg AS (
    SELECT
      ss_item_sk,
      ss_sold_date_sk,
      ss_sold_time_sk,
      ss_cdemo_sk,
      SUM(ss_ext_sales_price) AS store_total_sales,
      SUM(ss_quantity)       AS store_total_qty
    FROM store_sales_sampled
    GROUP BY
      ss_item_sk,
      ss_sold_date_sk,
      ss_sold_time_sk,
      ss_cdemo_sk
  ),
  /* Aggregate web sales */
  ws_agg AS (
    SELECT
      ws_item_sk,
      ws_sold_date_sk,
      ws_sold_time_sk,
      SUM(ws_ext_sales_price) AS web_total_sales
    FROM web_sales
    WHERE ws_ext_sales_price > 500
    GROUP BY
      ws_item_sk,
      ws_sold_date_sk,
      ws_sold_time_sk
  ),
  /* Aggregate catalog returns together with the reason key */
  returns_agg AS (
    SELECT
      cr_item_sk,
      cr_reason_sk,
      COUNT(*)                AS return_cnt,
      SUM(cr_return_amount)   AS return_amount_total
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY
      cr_item_sk,
      cr_reason_sk
  ),
  /* Items that never appeared in the sampled store sales */
  items_without_sales AS (
    SELECT i_item_sk
    FROM item
    EXCEPT
    SELECT ss_item_sk
    FROM store_sales_sampled
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  d.d_year,
  t.t_hour,
  ss_agg.store_total_sales,
  ws_agg.web_total_sales,
  ret.return_cnt,
  ret.return_amount_total,
  r.r_reason_desc,
  cd.cd_gender,
  year_variant,
  ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ss_agg.store_total_sales DESC) AS store_rank,
  AVG(ss_agg.store_total_sales) OVER (
    PARTITION BY d.d_year
    ORDER BY t.t_hour
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
  ) AS moving_avg_sales,
  (SELECT AVG(cr_return_amount) FROM catalog_returns) AS avg_return_amount
FROM ss_agg
JOIN date_dim d      ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t      ON ss_agg.ss_sold_time_sk = t.t_time_sk
JOIN item i          ON ss_agg.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN ws_agg          ON ws_agg.ws_item_sk = i.i_item_sk
                       AND ws_agg.ws_sold_date_sk = d.d_date_sk
                       AND ws_agg.ws_sold_time_sk = t.t_time_sk
JOIN returns_agg ret ON ret.cr_item_sk = i.i_item_sk
JOIN reason r        ON ret.cr_reason_sk = r.r_reason_sk
-- Expand an array derived from the year value
CROSS JOIN UNNEST(ARRAY[d.d_year, d.d_year + 1]) AS u(year_variant)
WHERE
  d.d_year BETWEEN 2000 AND 2002
  AND t.t_hour BETWEEN 9 AND 17
  AND i.i_brand = 'Brand#45'
  AND cd.cd_gender = 'M'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_return_amount > 500
      )
ORDER BY
  ss_agg.store_total_sales DESC,
  i.i_item_id
LIMIT 100
