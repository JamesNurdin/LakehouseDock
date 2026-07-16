WITH
store_sales_agg AS (
  SELECT ss.ss_item_sk AS item_sk,
         sum(ss.ss_net_paid) AS store_sales_total,
         sum(ss.ss_quantity) AS store_units
  FROM store_sales ss
  GROUP BY ss.ss_item_sk
),
catalog_sales_agg AS (
  SELECT cs.cs_item_sk AS item_sk,
         sum(cs.cs_net_paid) AS catalog_sales_total,
         sum(cs.cs_quantity) AS catalog_units
  FROM catalog_sales cs
  GROUP BY cs.cs_item_sk
),
web_sales_agg AS (
  SELECT ws.ws_item_sk AS item_sk,
         sum(ws.ws_net_paid) AS web_sales_total,
         sum(ws.ws_quantity) AS web_units
  FROM web_sales ws
  GROUP BY ws.ws_item_sk
),
sales_aggregates AS (
  SELECT item_sk,
         sum(store_sales_total) AS store_sales_total,
         sum(store_units) AS store_units,
         sum(catalog_sales_total) AS catalog_sales_total,
         sum(catalog_units) AS catalog_units,
         sum(web_sales_total) AS web_sales_total,
         sum(web_units) AS web_units
  FROM (
    SELECT item_sk, store_sales_total, store_units, 0 AS catalog_sales_total, 0 AS catalog_units, 0 AS web_sales_total, 0 AS web_units
    FROM store_sales_agg
    UNION ALL
    SELECT item_sk, 0, 0, catalog_sales_total, catalog_units, 0, 0
    FROM catalog_sales_agg
    UNION ALL
    SELECT item_sk, 0, 0, 0, 0, web_sales_total, web_units
    FROM web_sales_agg
  ) agg
  GROUP BY item_sk
),
store_item_sales AS (
  SELECT ss.ss_item_sk AS item_sk,
         s.s_store_name AS s_store_name,
         sum(ss.ss_net_paid) AS store_sales
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  GROUP BY ss.ss_item_sk, s.s_store_name
),
top_stores_per_item AS (
  SELECT item_sk,
         array_join(slice(array_agg(s_store_name ORDER BY store_sales DESC), 1, 3), ', ') AS top_3_stores
  FROM store_item_sales
  GROUP BY item_sk
),
item_sales_dates AS (
  SELECT ss.ss_item_sk AS item_sk, ss.ss_sold_date_sk AS date_sk FROM store_sales ss
  UNION ALL
  SELECT cs.cs_item_sk AS item_sk, cs.cs_sold_date_sk AS date_sk FROM catalog_sales cs
  UNION ALL
  SELECT ws.ws_item_sk AS item_sk, ws.ws_sold_date_sk AS date_sk FROM web_sales ws
),
item_latest_sale AS (
  SELECT isd.item_sk,
         max(d.d_date) AS latest_sale_date
  FROM item_sales_dates isd
  JOIN date_dim d ON isd.date_sk = d.d_date_sk
  GROUP BY isd.item_sk
)
SELECT
  i.i_item_id,
  i.i_product_name,
  lower(trim(i.i_product_name)) AS product_name_lower,
  regexp_replace(i.i_product_name, '\\s+', '_') AS product_name_underscored,
  substr(i.i_item_desc, 1, 50) AS item_desc_snippet,
  i.i_brand,
  i.i_category,
  replace(i.i_color, ' ', '') AS color_nospaces,
  concat(i.i_product_name, ' (', i.i_brand, ') - ', i.i_category) AS full_description,
  regexp_extract(i.i_item_id, '\\d+', 0) AS numeric_id_part,
  length(i.i_product_name) AS product_name_length,
  CASE WHEN regexp_like(i.i_product_name, '\\d') THEN 'contains_digit' ELSE 'no_digit' END AS name_digit_flag,
  ts.top_3_stores,
  coalesce(sa.store_sales_total, 0) AS store_sales_total,
  coalesce(sa.catalog_sales_total, 0) AS catalog_sales_total,
  coalesce(sa.web_sales_total, 0) AS web_sales_total,
  (coalesce(sa.store_sales_total, 0) + coalesce(sa.catalog_sales_total, 0) + coalesce(sa.web_sales_total, 0)) AS total_sales_amount,
  (coalesce(sa.store_units, 0) + coalesce(sa.catalog_units, 0) + coalesce(sa.web_units, 0)) AS total_units_sold,
  format('Item %s sold %s units for $%,.2f', i.i_item_id,
    (coalesce(sa.store_units, 0) + coalesce(sa.catalog_units, 0) + coalesce(sa.web_units, 0)),
    (coalesce(sa.store_sales_total, 0) + coalesce(sa.catalog_sales_total, 0) + coalesce(sa.web_sales_total, 0))) AS summary_string,
  format('%s | %s | %s',
    lower(i.i_product_name),
    lower(ts.top_3_stores),
    lower(i.i_category)) AS search_key,
  d.latest_sale_date
FROM item i
LEFT JOIN top_stores_per_item ts ON i.i_item_sk = ts.item_sk
LEFT JOIN sales_aggregates sa ON i.i_item_sk = sa.item_sk
LEFT JOIN item_latest_sale d ON i.i_item_sk = d.item_sk
WHERE i.i_product_name IS NOT NULL
ORDER BY total_sales_amount DESC
LIMIT 100
