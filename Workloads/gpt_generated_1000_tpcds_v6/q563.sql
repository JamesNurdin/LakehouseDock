WITH base AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_net_loss,
        r.r_reason_desc,
        w.w_warehouse_name,
        w.w_county,
        CASE
            WHEN regexp_like(r.r_reason_desc, '(?i)product') THEN 'Product Issue'
            WHEN regexp_like(r.r_reason_desc, '(?i)damaged') THEN 'Damaged Issue'
            ELSE 'Other'
        END AS reason_category
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_county LIKE '%County'
      AND (regexp_like(r.r_reason_desc, '(?i)product')
           OR regexp_like(r.r_reason_desc, '(?i)damaged'))
),
DamagedWarehouses AS (
    SELECT DISTINCT cr_warehouse_sk
    FROM base
    WHERE reason_category = 'Damaged Issue'
)
SELECT
    w.w_warehouse_name,
    w.w_county,
    CONCAT(w.w_warehouse_name, ' - ', w.w_county) AS full_location,
    COUNT(*) AS total_returns,
    SUM(b.cr_net_loss) AS total_net_loss,
    AVG(b.cr_net_loss) AS avg_net_loss,
    CASE
        WHEN SUM(b.cr_net_loss) > (SELECT AVG(cr_net_loss) FROM catalog_returns) THEN 'Above Avg Loss'
        ELSE 'Below Avg Loss'
    END AS loss_category
FROM base b
JOIN warehouse w ON b.cr_warehouse_sk = w.w_warehouse_sk
WHERE b.cr_warehouse_sk IN (SELECT cr_warehouse_sk FROM DamagedWarehouses)
GROUP BY
    w.w_warehouse_name,
    w.w_county,
    CONCAT(w.w_warehouse_name, ' - ', w.w_county)
ORDER BY total_net_loss DESC
LIMIT 100
