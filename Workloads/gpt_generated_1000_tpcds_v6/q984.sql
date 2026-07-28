WITH filtered_promos AS (
    SELECT p.p_promo_sk
    FROM promotion p
    WHERE regexp_like(p.p_channel_details, '(?i)high')
)
SELECT
    cp.cp_department,
    cp.cp_catalog_page_id,
    cp.cp_description,
    r.r_reason_desc,
    cr.cr_returned_date_sk,
    cr.cr_net_loss,
    CONCAT(cp.cp_department, '-', cp.cp_catalog_page_id) AS dept_page_key,
    SUM(cr.cr_net_loss) OVER (PARTITION BY cp.cp_department ORDER BY cr.cr_returned_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_loss,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY cr.cr_net_loss DESC) AS dept_loss_rank
FROM catalog_returns cr
JOIN catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
WHERE
    regexp_like(cp.cp_description, '(?i)new')
    AND p.p_promo_sk IN (SELECT p_promo_sk FROM filtered_promos)
    AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
    AND cr.cr_net_loss > (
        SELECT AVG(cr2.cr_net_loss)
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk BETWEEN 2450000 AND 2452000
    )
    AND cr.cr_net_loss > 0
ORDER BY cumulative_loss DESC
LIMIT 100
