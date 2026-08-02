WITH sales_promos AS (
   SELECT DISTINCT p.p_promo_id
   FROM promotion p
   JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 1995
),
return_promos AS (
   SELECT DISTINCT p.p_promo_id
   FROM promotion p
   JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                         AND cr.cr_item_sk = cs.cs_item_sk
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 1995
),
promo_sales_agg AS (
   SELECT
       p.p_promo_id,
       p.p_promo_name,
       p.p_purpose,
       d.d_year,
       SUM(cs.cs_net_paid) AS total_sales,
       SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
       CASE WHEN SUM(COALESCE(cr.cr_return_amount, 0)) > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_flag,
       CONCAT(p.p_promo_name, ' - ', p.p_purpose) AS promo_desc,
       REGEXP_EXTRACT(p.p_promo_name, '(\\d+)%') AS discount_percent,
       SUBSTR(p.p_promo_name, 1, 5) AS promo_prefix,
       MAX(r.r_reason_desc) AS return_reason_desc
   FROM promotion p
   JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
   LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                AND cr.cr_item_sk = cs.cs_item_sk
   LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 1995
     AND REGEXP_LIKE(p.p_promo_name, '.*Discount.*')
     AND d.d_quarter_name LIKE '%Q1%'
   GROUP BY GROUPING SETS (
       (p.p_promo_id, p.p_promo_name, p.p_purpose, d.d_year),
       (p.p_promo_id, d.d_year)
   )
   HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT
    pa.p_promo_id,
    pa.p_promo_name,
    pa.p_purpose,
    pa.d_year,
    pa.total_sales,
    pa.total_returns,
    pa.return_flag,
    pa.promo_desc,
    pa.discount_percent,
    pa.promo_prefix,
    pa.return_reason_desc
FROM promo_sales_agg pa
WHERE pa.p_promo_id IN (
    SELECT sp.p_promo_id FROM sales_promos sp
    EXCEPT
    SELECT rp.p_promo_id FROM return_promos rp
)
ORDER BY pa.total_sales DESC
LIMIT 100
