WITH
sr_base AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        t1.t_hour,
        i.i_current_price,
        i.i_category,
        c.c_customer_sk,
        hd.hd_income_band_sk,
        s.s_store_id,
        s.s_state
    FROM store_returns sr
    JOIN time_dim t1 ON sr.sr_return_time_sk = t1.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE i.i_current_price > 100
      AND hd.hd_income_band_sk IN (1, 2, 3, 4)
      AND s.s_state = 'CA'
      AND t1.t_hour BETWEEN 9 AND 17
),
cr_base AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        t2.t_hour,
        i.i_current_price,
        i.i_category,
        c_ref.c_customer_sk AS refunded_customer_sk,
        hd_ref.hd_income_band_sk AS refunded_income_band,
        sm.sm_type,
        w.w_warehouse_sq_ft,
        wp.wp_link_count
    FROM catalog_returns cr
    JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_customer_sk = c_ref.c_customer_sk
    WHERE sm.sm_type = 'AIR'
      AND w.w_warehouse_sq_ft > 20000
      AND wp.wp_link_count > 10
      AND i.i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
),
full_join AS (
    SELECT
        COALESCE(sr.sr_item_sk, cr.cr_item_sk) AS item_sk,
        sr.sr_return_quantity AS store_return_qty,
        cr.cr_return_quantity AS catalog_return_qty,
        sr.sr_return_amt AS store_return_amt,
        cr.cr_return_amount AS catalog_return_amt,
        sr.sr_net_loss AS store_net_loss,
        cr.cr_net_loss AS catalog_net_loss,
        sr.t_hour AS store_hour,
        cr.t_hour AS catalog_hour,
        sr.i_current_price,
        cr.i_current_price AS catalog_price,
        sr.s_state,
        cr.sm_type,
        cr.wp_link_count
    FROM sr_base sr
    FULL OUTER JOIN cr_base cr
        ON sr.sr_item_sk = cr.cr_item_sk
),
agg_per_item AS (
    SELECT
        item_sk,
        SUM(COALESCE(store_return_qty, 0)) AS total_store_qty,
        SUM(COALESCE(catalog_return_qty, 0)) AS total_catalog_qty,
        SUM(COALESCE(store_return_amt, 0)) AS total_store_amt,
        SUM(COALESCE(catalog_return_amt, 0)) AS total_catalog_amt,
        SUM(COALESCE(store_net_loss, 0) + COALESCE(catalog_net_loss, 0)) AS total_net_loss,
        MAX(i_current_price) AS max_price,
        COUNT(*) AS row_cnt
    FROM full_join
    WHERE item_sk IS NOT NULL
      AND item_sk IN (
          SELECT sr_item_sk FROM store_returns
          EXCEPT
          SELECT cr_item_sk FROM catalog_returns
      )
    GROUP BY item_sk
)
SELECT
    a.item_sk,
    a.total_store_qty,
    a.total_catalog_qty,
    a.total_store_amt,
    a.total_catalog_amt,
    a.total_net_loss,
    a.max_price,
    a.row_cnt,
    (a.total_store_amt + a.total_catalog_amt) / NULLIF(a.row_cnt, 0) AS avg_amt_per_row
FROM agg_per_item a
WHERE EXISTS (
    SELECT 1 FROM item i WHERE i.i_item_sk = a.item_sk AND i.i_color = 'Red'
)
ORDER BY a.total_net_loss DESC
LIMIT 100
