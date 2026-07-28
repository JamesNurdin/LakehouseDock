/* goal: Identify warehouses with the highest net loss from catalog returns for reasons related to gifts or exchanges, and compare to the overall average web return net loss for similar reasons. */
WITH catalog_agg AS (
    SELECT
        w.w_warehouse_sk,
        concat(w.w_warehouse_name, ' - ', w.w_city) AS warehouse_label,
        substring(w.w_warehouse_name, 1, 5) AS warehouse_prefix,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)gift|exchange')
      AND w.w_warehouse_name LIKE '%WAREHOUSE%'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city
)
SELECT
    ca.warehouse_label,
    ca.warehouse_prefix,
    ca.total_net_loss,
    ca.return_cnt,
    (
        SELECT AVG(wr.wr_net_loss)
        FROM web_returns wr
        JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
        WHERE regexp_like(r2.r_reason_desc, '(?i)gift|exchange')
    ) AS avg_web_net_loss
FROM catalog_agg ca
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN reason r3 ON wr.wr_reason_sk = r3.r_reason_sk
    WHERE regexp_like(r3.r_reason_desc, '(?i)gift|exchange')
      AND wr.wr_return_quantity > 0
)
ORDER BY ca.total_net_loss DESC
LIMIT 100
