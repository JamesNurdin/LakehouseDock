WITH unified_returns AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_returned_time_sk AS time_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_warehouse_sk AS warehouse_sk,
        cr.cr_call_center_sk AS call_center_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_catalog_page_sk AS catalog_page_sk,
        cr.cr_ship_mode_sk AS ship_mode_sk,
        'catalog' AS source
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_return_time_sk AS time_sk,
        sr.sr_item_sk AS item_sk,
        NULL AS warehouse_sk,
        NULL AS call_center_sk,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_customer_sk AS customer_sk,
        NULL AS catalog_page_sk,
        NULL AS ship_mode_sk,
        'store' AS source
    FROM store_returns sr
),
group_agg AS (
    SELECT
        cc.cc_call_center_id,
        w.w_warehouse_id,
        p.p_promo_id,
        d.d_year,
        i.i_brand,
        SUM(ur.net_loss) AS total_net_loss,
        AVG(ur.return_amount) AS avg_return_amount,
        COUNT(DISTINCT i.i_item_id) AS distinct_item_cnt,
        COUNT(*) AS total_returns,
        SUM(ur.return_quantity) AS total_return_quantity,
        COUNT(DISTINCT wp.wp_url) AS distinct_url_cnt
    FROM unified_returns ur
    JOIN date_dim d ON ur.date_sk = d.d_date_sk
    LEFT JOIN time_dim t ON ur.time_sk = t.t_time_sk
    LEFT JOIN item i ON ur.item_sk = i.i_item_sk
    LEFT JOIN customer c ON ur.customer_sk = c.c_customer_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON ur.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON ur.catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm ON ur.ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON ur.warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND w.w_state = 'CA'
      AND cc.cc_state = 'WA'
      AND hd.hd_buy_potential = '501-1000'
      AND p.p_discount_active = 'Y'
    GROUP BY
        cc.cc_call_center_id,
        w.w_warehouse_id,
        p.p_promo_id,
        d.d_year,
        i.i_brand
    HAVING SUM(ur.return_quantity) > 100
)
SELECT
    ga.cc_call_center_id,
    ga.w_warehouse_id,
    ga.p_promo_id,
    ga.d_year,
    ga.i_brand,
    ga.total_net_loss,
    ga.avg_return_amount,
    ga.distinct_item_cnt,
    ga.total_returns,
    ga.total_return_quantity,
    ga.distinct_url_cnt
FROM group_agg ga
WHERE ga.total_net_loss > (
    SELECT AVG(total_net_loss) FROM group_agg
)
ORDER BY ga.total_net_loss DESC
LIMIT 100
