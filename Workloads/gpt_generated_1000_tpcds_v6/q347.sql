WITH
  sales_by_item AS (
    SELECT
      i.i_item_id                                 AS item_id,
      i.i_product_name                           AS product_name,
      sm.sm_carrier                              AS carrier,
      SUM(ws.ws_ext_sales_price)                 AS total_sales,
      COUNT(*)                                   AS cnt_sales,
      CASE
        WHEN regexp_like(i.i_product_name, '^.*[A-Z]{3}.*$') THEN 'HAS3CAPS'
        ELSE 'OTHER'
      END                                        AS product_type
    FROM web_sales ws
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE sm.sm_carrier LIKE 'U%'                     -- carriers that start with "U"
      AND i.i_item_desc LIKE '%steel%'                -- description contains the word "steel"
      AND t.t_am_pm = 'PM'
    GROUP BY
      i.i_item_id,
      i.i_product_name,
      sm.sm_carrier,
      CASE
        WHEN regexp_like(i.i_product_name, '^.*[A-Z]{3}.*$') THEN 'HAS3CAPS'
        ELSE 'OTHER'
      END
  ),

  sales_by_item_alt AS (
    SELECT
      i.i_item_id                                 AS item_id,
      i.i_product_name                           AS product_name,
      sm.sm_carrier                              AS carrier,
      SUM(ws.ws_ext_sales_price)                 AS total_sales,
      COUNT(*)                                   AS cnt_sales,
      CASE
        WHEN regexp_like(i.i_item_desc, '.*[0-9]{2,}.*') THEN 'NUMERIC_DESC'
        ELSE 'NON_NUMERIC'
      END                                        AS product_type
    FROM web_sales ws
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE sm.sm_carrier LIKE '%S'                     -- carriers that end with "S"
      AND regexp_like(i.i_product_name, '^.*[0-9]+.*$')
      AND t.t_am_pm = 'AM'
    GROUP BY
      i.i_item_id,
      i.i_product_name,
      sm.sm_carrier,
      CASE
        WHEN regexp_like(i.i_item_desc, '.*[0-9]{2,}.*') THEN 'NUMERIC_DESC'
        ELSE 'NON_NUMERIC'
      END
  )

SELECT
  item_id,
  product_name,
  carrier,
  total_sales,
  cnt_sales,
  product_type,
  CONCAT('Item-', CAST(item_id AS VARCHAR))          AS item_key,
  ROW_NUMBER() OVER (PARTITION BY carrier ORDER BY total_sales DESC) AS rn_per_carrier
FROM (
  SELECT * FROM sales_by_item
  UNION ALL
  SELECT * FROM sales_by_item_alt
) AS combined
ORDER BY total_sales DESC
LIMIT 100
