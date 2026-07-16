WITH date_range AS (
  SELECT d_date_sk,
         d_date,
         CASE WHEN d_weekend = 'Y' THEN true ELSE false END AS is_weekend,
         row_number() OVER (ORDER BY d_date) AS day_seq
  FROM date_dim
  WHERE d_year = 2001
),
store_sales_agg AS (
  SELECT
    ss.ss_sold_date_sk AS date_sk,
    ds.d_date AS sales_date,
    s.s_store_sk AS store_sk,
    s.s_store_name AS store_name,
    ss.ss_item_sk AS item_sk,
    i.i_product_name AS product_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
  FROM store_sales ss
  JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE ds.d_year = 2001
  GROUP BY ss.ss_sold_date_sk, ds.d_date, s.s_store_sk, s.s_store_name, ss.ss_item_sk, i.i_product_name
),
web_sales_agg AS (
  SELECT
    ws.ws_sold_date_sk AS date_sk,
    dw.d_date AS sales_date,
    ws.ws_web_page_sk AS web_page_sk,
    wp.wp_url AS web_page_url,
    ws.ws_item_sk AS item_sk,
    i.i_product_name AS product_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
  FROM web_sales ws
  JOIN date_dim dw ON ws.ws_sold_date_sk = dw.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE dw.d_year = 2001
  GROUP BY ws.ws_sold_date_sk, dw.d_date, ws.ws_web_page_sk, wp.wp_url, ws.ws_item_sk, i.i_product_name
),
catalog_sales_agg AS (
  SELECT
    cs.cs_sold_date_sk AS date_sk,
    dc.d_date AS sales_date,
    cs.cs_catalog_page_sk AS catalog_page_sk,
    cp.cp_description AS catalog_page_desc,
    cs.cs_item_sk AS item_sk,
    i.i_product_name AS product_name,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS unique_customers
  FROM catalog_sales cs
  JOIN date_dim dc ON cs.cs_sold_date_sk = dc.d_date_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE dc.d_year = 2001
  GROUP BY cs.cs_sold_date_sk, dc.d_date, cs.cs_catalog_page_sk, cp.cp_description, cs.cs_item_sk, i.i_product_name
),
combined_sales AS (
  SELECT
    'store' AS channel,
    date_sk,
    sales_date,
    store_sk AS entity_sk,
    store_name AS entity_name,
    item_sk,
    product_name,
    total_sales,
    total_profit,
    total_quantity,
    avg_discount,
    unique_customers,
    NULL AS web_page_sk,
    NULL AS catalog_page_sk
  FROM store_sales_agg
  UNION ALL
  SELECT
    'web' AS channel,
    date_sk,
    sales_date,
    NULL AS entity_sk,
    NULL AS entity_name,
    item_sk,
    product_name,
    total_sales,
    total_profit,
    total_quantity,
    avg_discount,
    unique_customers,
    web_page_sk,
    NULL AS catalog_page_sk
  FROM web_sales_agg
  UNION ALL
  SELECT
    'catalog' AS channel,
    date_sk,
    sales_date,
    NULL AS entity_sk,
    NULL AS entity_name,
    item_sk,
    product_name,
    total_sales,
    total_profit,
    total_quantity,
    avg_discount,
    unique_customers,
    NULL AS web_page_sk,
    catalog_page_sk
  FROM catalog_sales_agg
),
sales_with_returns AS (
  SELECT
    cs.*,
    (
      SELECT COUNT(*)
      FROM store_returns sr
      WHERE sr.sr_item_sk = cs.item_sk
        AND sr.sr_returned_date_sk = cs.date_sk
    ) +
    (
      SELECT COUNT(*)
      FROM web_returns wr
      WHERE wr.wr_item_sk = cs.item_sk
        AND wr.wr_returned_date_sk = cs.date_sk
    ) +
    (
      SELECT COUNT(*)
      FROM catalog_returns cr
      WHERE cr.cr_item_sk = cs.item_sk
        AND cr.cr_returned_date_sk = cs.date_sk
    ) AS total_returns
  FROM combined_sales cs
),
ranked_sales AS (
  SELECT
    cs.*,
    dr.is_weekend,
    dr.day_seq,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_sales DESC NULLS LAST) AS sales_rank,
    SUM(total_sales) OVER (PARTITION BY channel ORDER BY sales_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
    (
      SELECT MAX(other.total_profit)
      FROM combined_sales other
      WHERE other.sales_date = cs.sales_date
        AND other.channel <> cs.channel
    ) AS max_other_channel_profit,
    reverse(substr(product_name, 1, 5)) AS rev_prod_prefix,
    COALESCE(NULLIF(total_profit, 0) / NULLIF(total_quantity, 0), 0) AS profit_per_quantity,
    CASE
      WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred'
      WHEN c.c_preferred_cust_flag IS NULL THEN 'Unknown'
      ELSE 'Regular'
    END AS customer_type
  FROM sales_with_returns cs
  LEFT JOIN date_range dr ON cs.date_sk = dr.d_date_sk
  LEFT JOIN customer c ON (
    CASE
      WHEN cs.channel = 'store' THEN cs.entity_sk
      ELSE NULL
    END
  ) = c.c_customer_sk
)
SELECT
  sales_date,
  channel,
  entity_name,
  product_name,
  total_sales,
  total_profit,
  total_returns,
  sales_rank,
  cumulative_sales,
  max_other_channel_profit,
  rev_prod_prefix,
  profit_per_quantity,
  customer_type,
  is_weekend,
  day_seq,
  CASE
    WHEN item_sk IN (
      SELECT sr_item_sk FROM store_returns INTERSECT SELECT wr_item_sk FROM web_returns
    ) THEN 'BothStoreWeb'
    ELSE 'Other'
  END AS multichannel_return_flag
FROM ranked_sales
WHERE (total_sales > 0 OR total_profit > 0)
ORDER BY sales_date DESC, channel, total_sales DESC NULLS LAST
LIMIT 100
