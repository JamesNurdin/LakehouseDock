WITH recent_years AS (
   SELECT d_date_sk, d_year
   FROM date_dim
   WHERE d_year BETWEEN 2001 AND 2002
)
SELECT q.entity_id,
       q.year,
       q.metric,
       q.category,
       q.extra_info
FROM (
   -- Store returns aggregated per store and year
   SELECT s.s_store_id AS entity_id,
          ry.d_year AS year,
          SUM(sr.sr_return_amt) AS metric,
          CASE WHEN SUM(sr.sr_return_amt) > 50000 THEN 'High' ELSE 'Low' END AS category,
          rc.reason_cnt AS extra_info
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN recent_years ry ON sr.sr_returned_date_sk = ry.d_date_sk
   CROSS JOIN LATERAL (
        SELECT COUNT(DISTINCT sr2.sr_reason_sk) AS reason_cnt
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = sr.sr_store_sk
          AND sr2.sr_returned_date_sk = sr.sr_returned_date_sk
   ) rc
   GROUP BY s.s_store_id, ry.d_year, rc.reason_cnt

   UNION ALL

   -- Catalog sales aggregated per customer and year
   SELECT c.c_customer_id AS entity_id,
          ry.d_year AS year,
          SUM(cs.cs_ext_sales_price) AS metric,
          CASE WHEN SUM(cs.cs_ext_sales_price) > 200000 THEN 'High' ELSE 'Low' END AS category,
          p.promos_used AS extra_info
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN recent_years ry ON cs.cs_sold_date_sk = ry.d_date_sk
   CROSS JOIN LATERAL (
        SELECT COUNT(DISTINCT cs2.cs_promo_sk) AS promos_used
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = cs.cs_bill_customer_sk
          AND cs2.cs_sold_date_sk = cs.cs_sold_date_sk
   ) p
   GROUP BY c.c_customer_id, ry.d_year, p.promos_used
) q
ORDER BY q.year DESC, q.metric DESC
LIMIT 100
