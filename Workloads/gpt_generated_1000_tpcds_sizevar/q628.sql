WITH combined_sales AS (
   SELECT cs.cs_sold_date_sk AS date_sk,
          cs.cs_net_paid_inc_ship_tax AS revenue
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   UNION   -- distinct union of catalog and web sales keys
   SELECT ws.ws_sold_date_sk AS date_sk,
          ws.ws_net_paid_inc_ship_tax AS revenue
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
intersect_dates AS (
   SELECT date_sk FROM combined_sales
   INTERSECT
   SELECT cs.cs_ship_date_sk AS date_sk
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
   WHERE d.d_quarter_seq = 13
),
cs_agg AS (
   SELECT cs.cs_sold_date_sk AS date_sk,
          SUM(cs.cs_net_paid_inc_ship_tax) AS cs_total_rev
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY cs.cs_sold_date_sk
),
ws_agg AS (
   SELECT ws.ws_sold_date_sk AS date_sk,
          SUM(ws.ws_net_paid_inc_ship_tax) AS ws_total_rev
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY ws.ws_sold_date_sk
)
SELECT
   COALESCE(c.date_sk, w.date_sk) AS sold_date_sk,
   c.cs_total_rev,
   w.ws_total_rev,
   (
      SELECT COUNT(DISTINCT cs_inner.cs_bill_customer_sk)
      FROM catalog_sales cs_inner
      WHERE cs_inner.cs_sold_date_sk = COALESCE(c.date_sk, w.date_sk)
   ) AS distinct_customers,
   CASE
      WHEN c.date_sk IS NOT NULL AND w.date_sk IS NOT NULL THEN 'Both'
      WHEN c.date_sk IS NOT NULL THEN 'CatalogOnly'
      ELSE 'WebOnly'
   END AS source_flag
FROM cs_agg c
FULL OUTER JOIN ws_agg w
   ON c.date_sk = w.date_sk
WHERE COALESCE(c.date_sk, w.date_sk) IN (SELECT date_sk FROM intersect_dates)
ORDER BY sold_date_sk
LIMIT 100
