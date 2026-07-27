WITH distinct_ship_modes AS (
    SELECT DISTINCT
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_type
    FROM ship_mode sm
    WHERE regexp_like(sm.sm_contract, '^.{5}[0-9]')
)
SELECT
    ds.sm_ship_mode_id,
    ds.sm_type,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_order_cnt,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    (
        SELECT AVG(cs_inner.cs_sales_price)
        FROM catalog_sales cs_inner
        WHERE cs_inner.cs_item_sk = i.i_item_sk
    ) AS avg_item_sales_price,
    REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1) AS desc_number
FROM catalog_returns cr
JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
JOIN distinct_ship_modes ds ON cr.cr_ship_mode_sk = ds.sm_ship_mode_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
WHERE d_ship.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-03-31'
  AND i.i_product_name LIKE '%Premium%'
  AND regexp_like(i.i_item_desc, '\\d+')
GROUP BY
    ds.sm_ship_mode_id,
    ds.sm_type,
    REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1),
    i.i_item_sk
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 50
