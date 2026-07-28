WITH sales_agg AS (
  SELECT
    i.i_category AS category,
    regexp_extract(i.i_item_desc, '^([A-Za-z]{3})', 1) AS item_prefix,
    CONCAT(i.i_brand, ':', i.i_color) AS brand_color,
    SUM(ws.ws_ext_sales_price) AS total_amount,
    'sales' AS src_type
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
    AND i.i_units LIKE 'C%'
  GROUP BY
    i.i_category,
    regexp_extract(i.i_item_desc, '^([A-Za-z]{3})', 1),
    CONCAT(i.i_brand, ':', i.i_color)
  HAVING SUM(ws.ws_ext_sales_price) > 10000
),
returns_agg AS (
  SELECT
    i.i_category AS category,
    regexp_extract(i.i_item_desc, '^([A-Za-z]{3})', 1) AS item_prefix,
    CONCAT(i.i_brand, ':', i.i_color) AS brand_color,
    -SUM(wr.wr_return_amt) AS total_amount,
    'returns' AS src_type
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
  WHERE regexp_like(ca.ca_city, '[A-Z]{2,}$')
    AND ca.ca_state LIKE 'C%'
  GROUP BY
    i.i_category,
    regexp_extract(i.i_item_desc, '^([A-Za-z]{3})', 1),
    CONCAT(i.i_brand, ':', i.i_color)
  HAVING SUM(wr.wr_return_amt) > 5000
)
SELECT *
FROM (
  SELECT category, item_prefix, brand_color, total_amount, src_type FROM sales_agg
  UNION ALL
  SELECT category, item_prefix, brand_color, total_amount, src_type FROM returns_agg
) combined
ORDER BY total_amount DESC
LIMIT 100
