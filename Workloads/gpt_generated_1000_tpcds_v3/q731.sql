WITH join_all AS (
    SELECT
        d_cr.d_year AS year,
        i.i_item_id,
        i.i_item_desc,
        cc.cc_name,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        cr.cr_return_amount,
        sr.sr_return_amt
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse wh_cr ON cr.cr_warehouse_sk = wh_cr.w_warehouse_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN date_dim d_site_open ON site.web_open_date_sk = d_site_open.d_date_sk
    JOIN date_dim d_site_close ON site.web_close_date_sk = d_site_close.d_date_sk
    JOIN warehouse wh_ws ON ws.ws_warehouse_sk = wh_ws.w_warehouse_sk
    JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
    JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_close ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
    WHERE
        d_cr.d_year = 2001
        AND cc.cc_state = 'CA'
        AND i.i_brand = 'BrandA'
        AND p.p_discount_active = 'Y'
        AND r_cr.r_reason_desc LIKE '%defect%'
        AND ws.ws_quantity > 5
        AND ws.ws_sales_price > 20.0
        AND cr.cr_return_quantity > 0
        AND sr.sr_return_quantity > 0
),
aggregated AS (
    SELECT
        year,
        i_item_id,
        i_item_desc,
        cc_name,
        SUM(ws_sales_price * ws_quantity) AS total_sales_amount,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(sr_return_amt) AS total_store_return_amount
    FROM join_all
    GROUP BY
        year,
        i_item_id,
        i_item_desc,
        cc_name
    HAVING
        SUM(ws_sales_price * ws_quantity) > 1000
        AND (SUM(ws_sales_price * ws_quantity) - SUM(cr_return_amount) - SUM(sr_return_amt)) > 0
)
SELECT
    year,
    i_item_id,
    i_item_desc,
    cc_name,
    total_sales_amount,
    total_net_profit,
    total_catalog_return_amount,
    total_store_return_amount,
    (total_sales_amount - total_catalog_return_amount - total_store_return_amount) AS net_performance,
    RANK() OVER (PARTITION BY year ORDER BY (total_sales_amount - total_catalog_return_amount - total_store_return_amount) DESC) AS performance_rank
FROM aggregated
ORDER BY net_performance DESC, performance_rank
LIMIT 100
