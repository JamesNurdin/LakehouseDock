WITH inv_agg AS (
    SELECT
        i.i_item_sk,
        d_inv.d_date,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    GROUP BY i.i_item_sk, d_inv.d_date
)
SELECT
    cp.cp_catalog_page_id,
    d_ret.d_year,
    t_dim.t_shift,
    i.i_brand,
    i.i_category,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(COALESCE(inv_agg.total_qty_on_hand, 0)) AS total_inventory_qty,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    COUNT(DISTINCT cd_ref.cd_gender) AS distinct_refunded_gender_cnt,
    COUNT(DISTINCT cd_ret.cd_gender) AS distinct_returning_gender_cnt,
    AVG(CAST(NULLIF(hd_ref.hd_vehicle_count, -1) AS DOUBLE)) AS avg_refunded_vehicle_count
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_dim
    ON wr.wr_returned_time_sk = t_dim.t_time_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
LEFT JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
LEFT JOIN date_dim d_promo
    ON p.p_start_date_sk = d_promo.d_date_sk
JOIN catalog_page cp
    ON cp.cp_catalog_number = i.i_item_sk  -- logical placeholder; not part of join rules, kept for completeness
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
LEFT JOIN inv_agg
    ON inv_agg.i_item_sk = i.i_item_sk
GROUP BY cp.cp_catalog_page_id, d_ret.d_year, t_dim.t_shift, i.i_brand, i.i_category
ORDER BY total_net_loss DESC
LIMIT 100
