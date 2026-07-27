WITH customer_high_returns AS (
       SELECT cr.cr_refunded_customer_sk AS customer_sk,
              SUM(cr.cr_return_quantity) AS total_qty
       FROM catalog_returns cr
       GROUP BY cr.cr_refunded_customer_sk
       HAVING SUM(cr.cr_return_quantity) > 5
   ),
   agg AS (
       SELECT
           r.r_reason_desc,
           r.r_reason_id,
           cp.cp_catalog_page_id,
           i.i_color,
           COUNT(*) AS num_returns,
           SUM(cr.cr_return_amount) AS total_return_amount,
           CONCAT(cp.cp_catalog_page_id, '-', r.r_reason_id) AS page_reason_key
       FROM catalog_returns cr
       JOIN item i               ON cr.cr_item_sk = i.i_item_sk
       JOIN reason r             ON cr.cr_reason_sk = r.r_reason_sk
       JOIN catalog_page cp      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
       JOIN customer_high_returns chr ON cr.cr_refunded_customer_sk = chr.customer_sk
       WHERE regexp_like(r.r_reason_desc, '^Did not like')
         AND i.i_color LIKE 's%'
       GROUP BY r.r_reason_desc, r.r_reason_id, cp.cp_catalog_page_id, i.i_color
       HAVING SUM(cr.cr_return_amount) > 100
   )
SELECT
    agg.r_reason_desc,
    agg.r_reason_id,
    agg.cp_catalog_page_id,
    agg.i_color,
    agg.num_returns,
    agg.total_return_amount,
    agg.page_reason_key,
    ROW_NUMBER() OVER (PARTITION BY agg.cp_catalog_page_id ORDER BY agg.total_return_amount DESC) AS rn
FROM agg
WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr_check
        JOIN reason r_check ON cr_check.cr_reason_sk = r_check.r_reason_sk
        WHERE r_check.r_reason_desc = agg.r_reason_desc
          AND cr_check.cr_return_amount > 0
    )
ORDER BY agg.total_return_amount DESC
LIMIT 20
