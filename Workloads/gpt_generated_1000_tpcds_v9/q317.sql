WITH filtered_returns AS (
    SELECT 
        cr.cr_warehouse_sk,
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        cp.cp_catalog_page_id,
        regexp_extract(cp.cp_catalog_page_id, '(\\d+)', 1) AS cp_prefix,
        cr.cr_net_loss,
        CASE 
            WHEN cr.cr_net_loss > 200 THEN 'High'
            WHEN cr.cr_net_loss > 50 THEN 'Medium'
            ELSE 'Low'
        END AS loss_bucket,
        cp.cp_description,
        r.r_reason_desc,
        substring(w.w_zip, 1, 3) AS zip_prefix
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(cp.cp_description, '(?i)discount|sale')
      AND cp.cp_type LIKE 'A%'
      AND CONCAT(w.w_city, ', ', w.w_state) LIKE 'San%'
      AND substring(w.w_zip, 1, 3) IN ('380', '336')
      AND d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr_f
          JOIN reason r_f ON cr_f.cr_reason_sk = r_f.r_reason_sk
          WHERE cr_f.cr_warehouse_sk = cr.cr_warehouse_sk
            AND regexp_like(r_f.r_reason_desc, '(?i)fraud')
      )
)
SELECT
    combined.w_warehouse_id,
    combined.page_prefix,
    combined.loss_bucket,
    combined.total_net_loss,
    combined.return_cnt
FROM (
    SELECT
        fr.w_warehouse_id,
        CONCAT('Prefix_', fr.cp_prefix) AS page_prefix,
        fr.loss_bucket,
        SUM(fr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM filtered_returns fr
    GROUP BY fr.w_warehouse_id, fr.cp_prefix, fr.loss_bucket

    UNION ALL

    SELECT
        fr.w_warehouse_id,
        'ALL_PREFIXES' AS page_prefix,
        fr.loss_bucket,
        SUM(fr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM filtered_returns fr
    GROUP BY fr.w_warehouse_id, fr.loss_bucket
) AS combined
ORDER BY combined.total_net_loss DESC
LIMIT 100
