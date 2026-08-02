WITH catalog_base AS (
   SELECT
     cs.cs_bill_customer_sk,
     cs.cs_quantity,
     cs.cs_ext_sales_price,
     cs.cs_ext_discount_amt,
     cp.cp_description,
     split(cp.cp_description, ' ') AS description_words
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2000-04-01'
),
catalog_exploded AS (
   SELECT
     cs_bill_customer_sk,
     cs_quantity,
     cs_ext_sales_price,
     cs_ext_discount_amt,
     word
   FROM catalog_base
   CROSS JOIN UNNEST(description_words) AS t(word)
   WHERE word <> ''
),
catalog_agg AS (
   SELECT
     word,
     SUM(cs_quantity) AS total_quantity,
     SUM(cs_ext_sales_price) AS total_sales,
     AVG(cs_ext_discount_amt) AS avg_discount,
     COUNT(DISTINCT cs_bill_customer_sk) AS distinct_customers
   FROM catalog_exploded
   GROUP BY word
),
web_base AS (
   SELECT
     ws.ws_bill_customer_sk,
     ws.ws_quantity,
     ws.ws_ext_sales_price,
     ws.ws_ext_discount_amt,
     wp.wp_url,
     split(wp.wp_url, '/') AS url_parts
   FROM web_sales ws
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2000-04-01'
),
web_exploded AS (
   SELECT
     ws_bill_customer_sk,
     ws_quantity,
     ws_ext_sales_price,
     ws_ext_discount_amt,
     part AS word
   FROM web_base
   CROSS JOIN UNNEST(url_parts) AS t(part)
   WHERE part <> ''
),
web_agg AS (
   SELECT
     word,
     SUM(ws_quantity) AS total_quantity,
     SUM(ws_ext_sales_price) AS total_sales,
     AVG(ws_ext_discount_amt) AS avg_discount,
     COUNT(DISTINCT ws_bill_customer_sk) AS distinct_customers
   FROM web_exploded
   GROUP BY word
)
SELECT
  word,
  CASE WHEN total_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS purchase_type,
  total_sales,
  total_quantity,
  avg_discount,
  distinct_customers,
  page_match_count,
  regexp_extract(word, '\\d+', 0) AS numeric_part
FROM (
  SELECT
    c.word,
    c.total_quantity,
    c.total_sales,
    c.avg_discount,
    c.distinct_customers,
    (SELECT COUNT(*) FROM catalog_page cp2 WHERE lower(cp2.cp_description) LIKE CONCAT('%', lower(c.word), '%')) AS page_match_count
  FROM catalog_agg c
  WHERE regexp_like(c.word, '[A-Za-z]{4,}')
    AND c.word LIKE '%e%'

  UNION DISTINCT

  SELECT
    w.word,
    w.total_quantity,
    w.total_sales,
    w.avg_discount,
    w.distinct_customers,
    (SELECT COUNT(*) FROM web_page wp2 WHERE lower(wp2.wp_url) LIKE CONCAT('%', lower(w.word), '%')) AS page_match_count
  FROM web_agg w
  WHERE regexp_like(w.word, '[A-Za-z]{4,}')
    AND w.word LIKE '%e%'
) AS combined
ORDER BY total_sales DESC
LIMIT 100
