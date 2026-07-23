WITH inventory_summary AS (
    SELECT inv_warehouse_sk,
           avg(inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 500
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_name AS warehouse_name,
    w.w_warehouse_id AS warehouse_id,
    regexp_extract(w.w_warehouse_id, '([0-9]+)') AS warehouse_num,
    concat(w.w_warehouse_name, ', ', w.w_city) AS warehouse_location,
    substring(w.w_state, 1, 3) AS state_prefix,
    i.avg_qty_on_hand,
    sum(cr.cr_net_loss) AS total_net_loss,
    count(*) AS return_cnt,
    case when regexp_like(cd_refunded.cd_education_status, 'College') then 'College' else 'Other' end AS education_category
FROM catalog_returns cr
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN inventory_summary i
    ON w.w_warehouse_sk = i.inv_warehouse_sk
WHERE trim(t.t_shift) = 'first'
  AND w.w_warehouse_name LIKE '%Warehouse%'
  AND w.w_warehouse_id LIKE 'WH%'
  AND regexp_like(cd_refunded.cd_education_status, 'College')
GROUP BY
    w.w_warehouse_name,
    w.w_warehouse_id,
    regexp_extract(w.w_warehouse_id, '([0-9]+)'),
    concat(w.w_warehouse_name, ', ', w.w_city),
    substring(w.w_state, 1, 3),
    i.avg_qty_on_hand,
    case when regexp_like(cd_refunded.cd_education_status, 'College') then 'College' else 'Other' end
ORDER BY total_net_loss DESC
LIMIT 10
