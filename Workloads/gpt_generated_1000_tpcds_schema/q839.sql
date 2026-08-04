WITH cr_agg AS (
   SELECT cr_returned_date_sk,
          COUNT(*) AS returns_cnt,
          SUM(cr_return_amount) AS total_return_amount,
          SUM(cr_return_quantity) AS total_quantity
   FROM catalog_returns
   WHERE cr_return_amount > 25
     AND cr_return_quantity BETWEEN 1 AND 5
     AND cr_returning_customer_sk IN (
         SELECT cr_returning_customer_sk
         FROM catalog_returns
         WHERE cr_return_amount > 1000
     )
   GROUP BY cr_returned_date_sk
),
order_exclusions AS (
   SELECT cr_order_number
   FROM catalog_returns
   WHERE cr_return_amount > 5000
),
order_inclusions AS (
   SELECT cr_order_number
   FROM catalog_returns
   WHERE cr_return_quantity = 1
),
order_diff AS (
   SELECT cr_order_number FROM order_inclusions
   EXCEPT
   SELECT cr_order_number FROM order_exclusions
),
order_common AS (
   SELECT cr_order_number FROM order_inclusions
   INTERSECT
   SELECT cr_order_number FROM order_exclusions
)
SELECT
   d.d_year,
   d.d_month_seq,
   ws.web_mkt_class,
   SUM(cr_agg.total_return_amount) AS sum_return_amount,
   SUM(cr_agg.total_quantity) AS sum_quantity,
   COUNT(DISTINCT ws.web_site_sk) AS distinct_sites,
   (SELECT MAX(cr_return_amount) FROM catalog_returns) AS max_return_amount_overall,
   (SELECT COUNT(*) FROM order_diff) AS diff_order_count,
   (SELECT COUNT(*) FROM order_common) AS common_order_count
FROM cr_agg
JOIN date_dim d
  ON cr_agg.cr_returned_date_sk = d.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND d.d_month_seq BETWEEN 1 AND 12
  AND d.d_week_seq = 10
  AND ws.web_mkt_class LIKE '%Severe%'
  AND ws.web_state = 'CA'
  AND ws.web_tax_percentage > 5.0
  AND cr_agg.cr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2002
  )
GROUP BY ROLLUP (d.d_year, d.d_month_seq, ws.web_mkt_class)
HAVING SUM(cr_agg.total_return_amount) > 1000
ORDER BY d.d_year NULLS LAST, d.d_month_seq NULLS LAST, ws.web_mkt_class
LIMIT 100
