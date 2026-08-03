WITH joined_all AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_order_number,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_addr_sk,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_net_loss,
        d.d_date,
        d.d_year,
        t.t_time_id,
        i.i_item_id,
        i.i_class_id,
        i.i_current_price,
        p.p_promo_name,
        p.p_channel_radio,
        s.s_store_id,
        s.s_store_name,
        s.s_gmt_offset,
        cc.cc_name,
        sm.sm_type,
        r.r_reason_desc,
        w.w_state,
        inv.inv_quantity_on_hand,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        cd.cd_gender,
        wp.wp_web_page_id,
        -- LATERAL derived column
        max_qty.max_quantity
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    FULL OUTER JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON i.i_item_sk = p.p_item_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN LATERAL (
        SELECT max(inv2.inv_quantity_on_hand) AS max_quantity
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
    ) max_qty ON true
    WHERE d.d_year = 2001
      AND i.i_class_id IN (3, 7, 11)
      AND p.p_channel_radio = 'N'
      AND w.w_state = 'CA'
      AND s.s_gmt_offset > -5.0
      AND r.r_reason_desc LIKE '%damage%'
),
sub_a AS (
    SELECT
        d_date,
        i_item_id,
        s_store_id,
        cr_return_amount,
        RANK() OVER (PARTITION BY s_store_id ORDER BY cr_return_amount DESC) AS rnk,
        CASE WHEN cr_return_amount > 2000 THEN 'HIGH' ELSE 'NORMAL' END AS amount_category,
        (SELECT avg(cr2.cr_return_amount)
         FROM catalog_returns cr2
         WHERE cr2.cr_returned_date_sk = cr_returned_date_sk) AS avg_return_amount,
        max_quantity
    FROM joined_all
    WHERE cr_return_amount > 0
),
sub_b AS (
    SELECT
        d_date,
        i_item_id,
        s_store_id,
        cr_return_amount,
        RANK() OVER (PARTITION BY s_store_id ORDER BY cr_return_amount DESC) AS rnk,
        CASE WHEN cr_return_amount > 2000 THEN 'HIGH' ELSE 'NORMAL' END AS amount_category,
        (SELECT avg(cr2.cr_return_amount)
         FROM catalog_returns cr2
         WHERE cr2.cr_returned_date_sk = cr_returned_date_sk) AS avg_return_amount,
        max_quantity
    FROM joined_all
    WHERE i_current_price > 100
),
union_set AS (
    SELECT DISTINCT d_date, i_item_id, s_store_id, cr_return_amount, rnk, amount_category, avg_return_amount, max_quantity
    FROM sub_a
    UNION
    SELECT DISTINCT d_date, i_item_id, s_store_id, cr_return_amount, rnk, amount_category, avg_return_amount, max_quantity
    FROM sub_b
),
intersect_keys AS (
    SELECT d_date, i_item_id, s_store_id
    FROM joined_all
    WHERE cr_return_quantity > 1
    INTERSECT
    SELECT d_date, i_item_id, s_store_id
    FROM joined_all
    WHERE cr_return_amount > 500
)
SELECT
    us.d_date,
    us.i_item_id,
    us.s_store_id,
    us.cr_return_amount,
    us.rnk,
    us.amount_category,
    us.avg_return_amount,
    us.max_quantity
FROM union_set us
JOIN intersect_keys ik
  ON us.d_date = ik.d_date
 AND us.i_item_id = ik.i_item_id
 AND us.s_store_id = ik.s_store_id
ORDER BY us.d_date DESC, us.cr_return_amount DESC
LIMIT 100
