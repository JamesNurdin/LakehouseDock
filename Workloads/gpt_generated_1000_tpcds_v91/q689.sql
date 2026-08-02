WITH date_store AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_sk,
        s.s_store_id,
        s.s_company_name,
        s.s_state
    FROM date_dim d
    FULL OUTER JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
       AND d.d_year = 2001
),
promotion_active AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_item_sk,
        p.p_start_date_sk,
        p.p_discount_active
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
warehouse_ca AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        w.w_zip
    FROM warehouse w
    WHERE w.w_state = 'CA'
),
inventory_positive AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_warehouse_sk,
        inv.inv_item_sk,
        inv.inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 0
),
base_aggregated AS (
    SELECT
        ds.d_date,
        ds.d_year,
        ds.d_month_seq,
        wca.w_warehouse_id,
        wca.w_city,
        p_active.p_promo_id,
        COUNT(*) AS total_return_rows,
        SUM(cr.cr_return_amount) AS sum_return_amount,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS sum_web_return_amount,
        SUM(cr.cr_net_loss) AS sum_net_loss,
        AVG(inv_pos.inv_quantity_on_hand) AS avg_inventory_qty,
        MAX(cr.cr_return_quantity) AS max_return_qty,
        MIN(cr.cr_return_quantity) AS min_return_qty,
        (
            SELECT COUNT(*)
            FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = cr.cr_item_sk
              AND cr2.cr_returned_date_sk = ds.d_date_sk
        ) AS item_return_count_on_date,
        ds.d_date_sk,
        cr.cr_item_sk
    FROM date_store ds
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = ds.d_date_sk
    JOIN time_dim t
        ON t.t_time_sk = cr.cr_returned_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = ds.d_date_sk
       AND wr.wr_returned_time_sk = t.t_time_sk
    JOIN warehouse_ca wca
        ON wca.w_warehouse_sk = cr.cr_warehouse_sk
    LEFT JOIN inventory_positive inv_pos
        ON inv_pos.inv_date_sk = ds.d_date_sk
       AND inv_pos.inv_warehouse_sk = wca.w_warehouse_sk
    LEFT JOIN promotion_active p_active
        ON p_active.p_start_date_sk = ds.d_date_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND cr.cr_return_amount > 500
      AND NOT EXISTS (
          SELECT 1
          FROM inventory inv2
          WHERE inv2.inv_item_sk = cr.cr_item_sk
            AND inv2.inv_date_sk = ds.d_date_sk
            AND inv2.inv_quantity_on_hand > 0
      )
    GROUP BY
        ds.d_date,
        ds.d_year,
        ds.d_month_seq,
        wca.w_warehouse_id,
        wca.w_city,
        p_active.p_promo_id,
        ds.d_date_sk,
        cr.cr_item_sk
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    ba.d_date,
    ba.d_year,
    ba.d_month_seq,
    ba.w_warehouse_id,
    ba.w_city,
    ba.p_promo_id,
    ba.total_return_rows,
    ba.sum_return_amount,
    ba.sum_web_return_amount,
    ba.sum_net_loss,
    ba.avg_inventory_qty,
    ba.max_return_qty,
    ba.min_return_qty,
    ba.item_return_count_on_date,
    SUM(ba.sum_return_amount) OVER (
        PARTITION BY ba.w_warehouse_id
        ORDER BY ba.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_sum_return_amount
FROM base_aggregated ba
ORDER BY ba.d_date DESC, ba.w_warehouse_id
LIMIT 100
