WITH open_agg AS (
   SELECT d.d_year,
          p.p_promo_name,
          SUM(cr.cr_return_amount) AS total_return_amount,
          COUNT(*) AS return_cnt
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
   JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
   JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND cr.cr_return_amount > 50
     AND ca_ref.ca_state = 'CA'
     AND w.web_country = 'United States'
   GROUP BY d.d_year, p.p_promo_name
),
close_agg AS (
   SELECT d.d_year,
          p.p_promo_name,
          SUM(cr.cr_return_amount) AS total_return_amount,
          COUNT(*) AS return_cnt
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
   JOIN promotion p ON p.p_end_date_sk = d.d_date_sk
   JOIN web_site w ON w.web_close_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND cr.cr_return_amount > 50
     AND ca_ref.ca_state = 'CA'
     AND w.web_country = 'United States'
   GROUP BY d.d_year, p.p_promo_name
),
union_all AS (
   SELECT * FROM open_agg
   UNION ALL
   SELECT * FROM close_agg
),
filtered AS (
   SELECT *
   FROM union_all u
   WHERE NOT EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_name = u.p_promo_name
          AND p2.p_cost > 1000
   )
)
SELECT f.d_year,
       f.p_promo_name,
       SUM(f.total_return_amount) AS summed_return_amount,
       SUM(f.return_cnt) AS total_returns,
       AVG(f.total_return_amount) AS avg_return_amount_per_group
FROM filtered f
GROUP BY f.d_year, f.p_promo_name
HAVING SUM(f.total_return_amount) > 1000
ORDER BY f.d_year DESC, summed_return_amount DESC
LIMIT 100
