WITH filtered AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_city,
        regexp_extract(w.w_warehouse_id, '(\\d+)$') AS id_suffix,
        w.w_street_type,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
      AND regexp_like(w.w_warehouse_id, '^AAAA{3,}.*')
      AND w.w_street_type LIKE '%e'
      AND substring(w.w_warehouse_name, 1, 5) = 'North'
)
SELECT
    id_suffix,
    w_city,
    COUNT(*) AS returns_count,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_quantity) AS avg_return_quantity
FROM filtered
GROUP BY id_suffix, w_city
HAVING SUM(cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 20
