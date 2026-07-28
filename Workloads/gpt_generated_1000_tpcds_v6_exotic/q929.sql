WITH sr_agg AS (
    SELECT
        sr_item_sk,
        SUM(sr_net_loss) AS total_sr_net_loss,
        COUNT(*) AS cnt_sr
    FROM store_returns
    WHERE sr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2002 AND d_month_seq = 12
    )
    GROUP BY sr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d_cr.d_year,
    d_cr.d_month_seq,
    sm.sm_type,
    w.w_state,
    p.p_promo_name,
    r_cr.r_reason_desc,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr_agg.total_sr_net_loss) AS total_store_return_net_loss,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    COUNT(DISTINCT cr.cr_order_number) AS cnt_catalog_orders,
    CASE WHEN sm.sm_type = 'AIR' THEN SUM(cr.cr_net_loss) ELSE 0 END AS air_net_loss
FROM catalog_returns cr
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN sr_agg ON sr_agg.sr_item_sk = i.i_item_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
JOIN date_dim d_p_end ON p.p_end_date_sk = d_p_end.d_date_sk
WHERE d_cr.d_year = 2002
  AND i.i_brand_id = 5
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'CA'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    d_cr.d_year,
    d_cr.d_month_seq,
    sm.sm_type,
    w.w_state,
    p.p_promo_name,
    r_cr.r_reason_desc
HAVING SUM(cr.cr_return_amount) > 1000
LIMIT 100
