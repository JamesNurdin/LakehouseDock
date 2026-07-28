WITH returns_by_item AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        ca.ca_state AS customer_state,
        w.w_state AS warehouse_state,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
      AND t.t_hour BETWEEN 8 AND 17
      AND i.i_brand = 'Brand#45'
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'TX'
      AND inv.inv_quantity_on_hand > 0
      AND cr.cr_return_amount > 10
    GROUP BY i.i_item_id, i.i_brand, ca.ca_state, w.w_state, d.d_year
),
item_average AS (
    SELECT
        i_item_id,
        i_brand,
        customer_state,
        warehouse_state,
        d_year,
        total_return_amount,
        total_return_qty,
        return_cnt,
        avg_return_amount,
        total_return_amount / NULLIF(total_return_qty, 0) AS return_amount_per_qty
    FROM returns_by_item
    WHERE total_return_qty > 100
)
SELECT
    i_item_id,
    i_brand,
    customer_state,
    warehouse_state,
    d_year,
    total_return_amount,
    total_return_qty,
    return_cnt,
    avg_return_amount,
    return_amount_per_qty
FROM item_average
ORDER BY return_amount_per_qty DESC
LIMIT 100
