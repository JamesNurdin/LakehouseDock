WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_warehouse_sk,
        cr.cr_net_loss,
        cr.cr_reason_sk
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(w.w_street_name, '\\d')
      AND w.w_zip LIKE '3%'
),
agg_returns AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        w.w_warehouse_name AS warehouse_name,
        d.d_year AS d_year,
        SUM(fr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        r.r_reason_desc AS reason_desc
    FROM filtered_returns fr
    JOIN warehouse w
        ON fr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d
        ON fr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON fr.cr_reason_sk = r.r_reason_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, d.d_year, r.r_reason_desc
)
SELECT
    warehouse_id,
    warehouse_name,
    d_year,
    CASE
        WHEN total_net_loss > 1000 THEN 'High'
        WHEN total_net_loss > 100 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    total_net_loss,
    return_count,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS rn
FROM agg_returns
WHERE regexp_like(reason_desc, '(?i)defect')
ORDER BY d_year DESC, total_net_loss DESC
LIMIT 100
