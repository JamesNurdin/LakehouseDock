WITH promo_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        p.p_start_date_sk,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        SUM(cr.cr_fee) AS total_fee
    FROM catalog_returns cr
    JOIN promotion p
      ON cr.cr_item_sk = p.p_item_sk
      AND cr.cr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    WHERE cr.cr_return_amt_inc_tax > 0
      AND p.p_cost >= 1000
    GROUP BY p.p_promo_id, p.p_promo_name, p.p_cost, p.p_start_date_sk
    HAVING SUM(cr.cr_return_amt_inc_tax) > 5000
)
SELECT
    pa.p_promo_id,
    pa.p_promo_name,
    pa.p_cost AS promo_cost,
    pa.return_cnt,
    pa.total_return_amount,
    pa.avg_return_tax,
    pa.total_fee,
    COALESCE(wp.page_cnt, 0) AS pages_created_at_start,
    ROW_NUMBER() OVER (ORDER BY pa.total_return_amount DESC) AS promo_rank
FROM promo_agg pa
LEFT JOIN (
    SELECT
        wp_creation_date_sk,
        COUNT(*) AS page_cnt
    FROM web_page
    GROUP BY wp_creation_date_sk
) wp
  ON wp.wp_creation_date_sk = pa.p_start_date_sk
ORDER BY pa.total_return_amount DESC
LIMIT 20
