WITH returns_by_date AS (
   SELECT
      d.d_date_id,
      d.d_date,
      d.d_date_sk,
      COUNT(cr.cr_order_number) AS num_returns,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(CASE WHEN regexp_like(d.d_date_id, '^AAAA.*ELJ') THEN cr.cr_return_amount ELSE 0 END) AS pattern_return_amount,
      regexp_extract(d.d_date_id, '(....)', 1) AS date_prefix
   FROM
      date_dim d
   RIGHT OUTER JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
   GROUP BY
      d.d_date_id,
      d.d_date,
      d.d_date_sk,
      regexp_extract(d.d_date_id, '(....)', 1)
),

max_shift AS (
   SELECT
      cr.cr_returned_date_sk,
      t.t_shift,
      SUM(cr.cr_return_amount) AS shift_return_amount,
      ROW_NUMBER() OVER (PARTITION BY cr.cr_returned_date_sk ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
   FROM
      catalog_returns cr
   JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
   GROUP BY
      cr.cr_returned_date_sk,
      t.t_shift
)

SELECT DISTINCT
   rbd.d_date_id,
   rbd.d_date,
   rbd.date_prefix,
   rbd.num_returns,
   rbd.total_return_amount,
   rbd.pattern_return_amount,
   CASE
      WHEN rbd.total_return_amount > (SELECT AVG(cr_inner.cr_return_amount) FROM catalog_returns cr_inner) THEN 'ABOVE_AVG'
      ELSE 'BELOW_AVG'
   END AS return_category,
   COALESCE(ms.t_shift, 'NO_SHIFT') AS top_shift
FROM
   returns_by_date rbd
LEFT JOIN (
   SELECT cr_returned_date_sk, t_shift
   FROM max_shift
   WHERE rn = 1
) ms
   ON rbd.d_date_sk = ms.cr_returned_date_sk
WHERE
   rbd.d_date_id LIKE 'AAAA%'
   AND EXISTS (
       SELECT 1
       FROM catalog_returns cr4
       WHERE cr4.cr_returned_date_sk = rbd.d_date_sk
         AND cr4.cr_return_quantity > 5
   )
ORDER BY
   rbd.total_return_amount DESC
LIMIT 50
