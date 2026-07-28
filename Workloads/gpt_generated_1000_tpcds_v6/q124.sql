WITH returns_detail AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_returned_date_sk,
        cp.cp_catalog_page_id,
        cp.cp_description,
        cp.cp_type,
        d.d_year,
        r.r_reason_desc,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        d.d_date_sk
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_description LIKE '%sale%'
      AND regexp_like(cp.cp_description, '(?i)discount')
      AND r.r_reason_desc LIKE '%damage%'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
            AND inv.inv_date_sk = d.d_date_sk
            AND inv.inv_quantity_on_hand > 0
      )
),
aggregated AS (
    SELECT
        rd.cp_catalog_page_id,
        rd.d_year,
        rd.w_warehouse_name,
        rd.r_reason_desc,
        COUNT(*) AS return_cnt,
        AVG(rd.cr_return_amount) AS avg_return_amount,
        SUM(rd.cr_net_loss) AS total_net_loss
    FROM returns_detail rd
    GROUP BY rd.cp_catalog_page_id, rd.d_year, rd.w_warehouse_name, rd.r_reason_desc
    HAVING COUNT(*) > 5
)
SELECT
    a.cp_catalog_page_id,
    a.d_year,
    a.return_cnt,
    a.avg_return_amount,
    a.total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.avg_return_amount DESC) AS rank_in_year,
    (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) AS overall_avg_return_amount,
    CONCAT(a.w_warehouse_name, ' - ', a.r_reason_desc) AS warehouse_reason
FROM aggregated a
ORDER BY a.d_year DESC, a.avg_return_amount DESC
LIMIT 100
