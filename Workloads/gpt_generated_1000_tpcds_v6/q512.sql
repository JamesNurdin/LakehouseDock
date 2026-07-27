WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_ticket_number,
        d.d_year,
        d.d_current_year
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
      AND d.d_current_year = 'Y'
      AND sr.sr_return_quantity > 0
)
SELECT
    cp.cp_department,
    p.p_promo_name,
    wp.wp_type,
    COUNT(DISTINCT base.sr_ticket_number) AS distinct_tickets,
    SUM(base.sr_return_amt) AS total_return_amount,
    AVG(p.p_cost) AS avg_promo_cost,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    MIN(base.sr_return_amt) AS min_return,
    MAX(base.sr_return_amt) AS max_return
FROM base
JOIN catalog_page cp
    ON cp.cp_end_date_sk = base.sr_returned_date_sk
JOIN promotion p
    ON p.p_start_date_sk = base.sr_returned_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = base.sr_returned_date_sk
WHERE cp.cp_type = 'Catalog'
  AND p.p_cost > 10
  AND wp.wp_type = 'Home'
GROUP BY
    cp.cp_department,
    p.p_promo_name,
    wp.wp_type,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END
ORDER BY total_return_amount DESC
LIMIT 100
