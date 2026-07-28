WITH page_returns AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_description,
        cp.cp_type,
        sm.sm_carrier,
        d.d_year,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        REGEXP_EXTRACT(cp.cp_description, '(\\w+)', 1) AS first_word
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE REGEXP_LIKE(cp.cp_description, '(?i)classic')
      AND cp.cp_type LIKE 'monthly%'
      AND sm.sm_carrier LIKE 'U%'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_description,
        cp.cp_type,
        sm.sm_carrier,
        d.d_year,
        REGEXP_EXTRACT(cp.cp_description, '(\\w+)', 1)
)
SELECT
    pr.cp_catalog_page_id,
    pr.cp_type,
    pr.sm_carrier,
    pr.d_year,
    pr.first_word,
    pr.total_net_loss,
    pr.return_cnt,
    CASE
        WHEN pr.total_net_loss > (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) THEN 'HIGH'
        ELSE 'LOW'
    END AS loss_category
FROM page_returns pr
WHERE pr.return_cnt > 5
ORDER BY pr.total_net_loss DESC
LIMIT 100
