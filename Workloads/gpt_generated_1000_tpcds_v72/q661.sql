WITH base AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_country,
        cc.cc_gmt_offset,
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk,
        cr.cr_reason_sk,
        cr.cr_warehouse_sk,
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        p.p_promo_sk AS promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        ws.ws_quantity,
        ws.ws_ext_ship_cost,
        ws.ws_net_paid,
        ws.ws_web_site_sk,
        w.w_warehouse_sk,
        w.w_city,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_sales ss
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
     AND ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN web_sales ws
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
     AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
     AND ws.ws_warehouse_sk = w.w_warehouse_sk
     AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_site web
      ON ws.ws_web_site_sk = web.web_site_sk
)
SELECT
    cc_name,
    cr_order_number,
    cr_return_amount,
    CASE WHEN cr_return_amount > 0 THEN 'Refund' ELSE 'No Refund' END AS return_type,
    p_promo_name,
    ws_quantity,
    ws_ext_ship_cost,
    avg_ws_net_paid,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY cr_net_loss DESC) AS rank_in_center
FROM base
CROSS JOIN LATERAL (
    SELECT avg(ws_inner.ws_net_paid) AS avg_ws_net_paid
    FROM web_sales ws_inner
    WHERE ws_inner.ws_promo_sk = base.promo_sk
) AS l
WHERE
    cc_country = 'United States'
    AND cc_gmt_offset > 0
    AND cr_net_loss > 1000
    AND cr_return_quantity BETWEEN 1 AND 5
    AND ws_quantity > 20
    AND ws_ext_ship_cost < 2000
    AND p_discount_active = 'Y'
LIMIT 100
