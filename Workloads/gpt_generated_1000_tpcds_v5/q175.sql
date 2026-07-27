WITH filtered AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        c.c_customer_id,
        c.c_birth_month,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        sm.sm_type,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        i.inv_quantity_on_hand,
        p.p_promo_name
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND c.c_birth_month IN (5, 10)
      AND w.w_warehouse_sq_ft > 500000
      AND sm.sm_type = 'AIR'
      AND cr.cr_return_amount > 100
      AND t.t_hour BETWEEN 8 AND 17
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM inventory i2
          WHERE i2.inv_item_sk = cr.cr_item_sk
            AND i2.inv_quantity_on_hand > 500
      )
)
SELECT DISTINCT
    c_customer_id,
    d_year,
    w_warehouse_name,
    sm_type,
    COUNT(*) AS returns_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_return_qty,
    MIN(cr_net_loss) AS min_net_loss,
    MAX(cr_net_loss) AS max_net_loss
FROM filtered
GROUP BY c_customer_id, d_year, w_warehouse_name, sm_type
ORDER BY total_return_amount DESC
LIMIT 100
