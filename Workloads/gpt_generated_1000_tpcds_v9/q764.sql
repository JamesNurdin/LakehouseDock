WITH store_ret AS (
    SELECT 
        sr.sr_returned_date_sk AS returned_date_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_cdemo_sk AS cdemo_sk,
        sr.sr_hdemo_sk AS hdemo_sk,
        sr.sr_store_sk AS store_sk,
        CAST(NULL AS INTEGER) AS call_center_sk,
        CAST(NULL AS INTEGER) AS catalog_page_sk,
        CAST(NULL AS INTEGER) AS ship_mode_sk,
        CAST(NULL AS INTEGER) AS warehouse_sk,
        CAST(NULL AS INTEGER) AS web_page_sk,
        sr.sr_reason_sk AS reason_sk,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_return_amt AS return_amt,
        sr.sr_net_loss AS net_loss,
        'store' AS source
    FROM store_returns sr
),
catalog_ret AS (
    SELECT 
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_refunded_cdemo_sk AS cdemo_sk,
        cr.cr_refunded_hdemo_sk AS hdemo_sk,
        CAST(NULL AS INTEGER) AS store_sk,
        cr.cr_call_center_sk AS call_center_sk,
        cr.cr_catalog_page_sk AS catalog_page_sk,
        cr.cr_ship_mode_sk AS ship_mode_sk,
        cr.cr_warehouse_sk AS warehouse_sk,
        CAST(NULL AS INTEGER) AS web_page_sk,
        cr.cr_reason_sk AS reason_sk,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_amount AS return_amt,
        cr.cr_net_loss AS net_loss,
        'catalog' AS source
    FROM catalog_returns cr
),
web_ret AS (
    SELECT 
        wr.wr_returned_date_sk AS returned_date_sk,
        wr.wr_item_sk AS item_sk,
        wr.wr_refunded_customer_sk AS customer_sk,
        wr.wr_refunded_cdemo_sk AS cdemo_sk,
        wr.wr_refunded_hdemo_sk AS hdemo_sk,
        CAST(NULL AS INTEGER) AS store_sk,
        CAST(NULL AS INTEGER) AS call_center_sk,
        CAST(NULL AS INTEGER) AS catalog_page_sk,
        CAST(NULL AS INTEGER) AS ship_mode_sk,
        CAST(NULL AS INTEGER) AS warehouse_sk,
        wr.wr_web_page_sk AS web_page_sk,
        wr.wr_reason_sk AS reason_sk,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_amt AS return_amt,
        wr.wr_net_loss AS net_loss,
        'web' AS source
    FROM web_returns wr
),
all_ret AS (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM catalog_ret
    UNION ALL
    SELECT * FROM web_ret
),
customer_agg AS (
    SELECT
        ar.customer_sk,
        SUM(ar.net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM all_ret ar
    GROUP BY ar.customer_sk
),
ranked_customers AS (
    SELECT
        ca.customer_sk,
        ca.total_net_loss,
        ca.return_cnt,
        RANK() OVER (ORDER BY ca.total_net_loss DESC) AS net_loss_rank
    FROM customer_agg ca
)
SELECT DISTINCT
    d.d_date,
    c.c_customer_id,
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    r.r_reason_desc,
    s.s_store_name,
    cc.cc_name,
    cp.cp_catalog_number,
    wp.wp_url,
    rc.total_net_loss,
    rc.net_loss_rank,
    ar.return_quantity,
    ar.return_amt,
    ar.net_loss,
    (SELECT MAX(w2.w_warehouse_sq_ft) FROM warehouse w2) AS max_warehouse_sq_ft
FROM all_ret ar
JOIN date_dim d
    ON ar.returned_date_sk = d.d_date_sk
JOIN item i
    ON ar.item_sk = i.i_item_sk
JOIN customer c
    ON ar.customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ar.cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ar.hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN reason r
    ON ar.reason_sk = r.r_reason_sk
LEFT JOIN store s
    ON ar.store_sk = s.s_store_sk
LEFT JOIN call_center cc
    ON ar.call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
    ON ar.catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm
    ON ar.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
    ON ar.warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_page wp
    ON ar.web_page_sk = wp.wp_web_page_sk
LEFT JOIN ranked_customers rc
    ON ar.customer_sk = rc.customer_sk
WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
  AND r.r_reason_desc = 'Found a better extended warranty in a store'
  AND i.i_current_price > 100
  AND cd.cd_gender = 'M'
ORDER BY rc.total_net_loss DESC, d.d_date
LIMIT 100
