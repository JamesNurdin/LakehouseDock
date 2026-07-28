WITH base AS (
   SELECT
       c.c_customer_id,
       c.c_customer_sk,
       d.d_year,
       cp.cp_department,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_cnt,
       hd.hd_vehicle_count,
       s.s_state,
       MIN(d.d_date) AS first_return_date
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
   JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND cp.cp_department = 'Books'
     AND cp.cp_catalog_page_number > 10
     AND hd.hd_vehicle_count >= 2
     AND p.p_discount_active = 'Y'
     AND s.s_state = 'CA'
     AND NOT EXISTS (
         SELECT 1
         FROM catalog_returns cr2
         JOIN promotion p2 ON p2.p_end_date_sk = cr2.cr_returned_date_sk
         WHERE cr2.cr_returning_customer_sk = c.c_customer_sk
           AND p2.p_promo_name LIKE '%Clearance%'
     )
   GROUP BY
       c.c_customer_id,
       c.c_customer_sk,
       d.d_year,
       cp.cp_department,
       hd.hd_vehicle_count,
       s.s_state
)
SELECT
    b.c_customer_id,
    b.d_year,
    b.cp_department,
    b.total_return_amount,
    b.return_cnt,
    b.hd_vehicle_count,
    b.s_state,
    RANK() OVER (PARTITION BY b.d_year ORDER BY b.total_return_amount DESC) AS yearly_return_rank,
    SUM(b.total_return_amount) OVER (PARTITION BY b.c_customer_sk ORDER BY b.first_return_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_return
FROM base b
ORDER BY b.total_return_amount DESC
LIMIT 100
