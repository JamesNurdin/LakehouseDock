WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    WHERE inv_warehouse_sk IN (5, 8, 16)
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    i.i_category,
    w.w_state,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(inv_agg.total_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT p.p_promo_sk) AS promo_count,
    AVG(ws.ws_ext_discount_amt) AS avg_discount
FROM
    web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d_sold.d_date_sk
        AND sr.sr_return_time_sk = t_sold.t_time_sk
        AND sr.sr_cdemo_sk = cd_bill.cd_demo_sk
        AND sr.sr_hdemo_sk = hd_bill.hd_demo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d_sold.d_date_sk
        AND cr.cr_returned_time_sk = t_sold.t_time_sk
        AND cr.cr_refunded_cdemo_sk = cd_bill.cd_demo_sk
        AND cr.cr_refunded_hdemo_sk = hd_bill.hd_demo_sk
        AND cr.cr_returning_cdemo_sk = cd_bill.cd_demo_sk
        AND cr.cr_returning_hdemo_sk = hd_bill.hd_demo_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
        AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    d_sold.d_year = 2001
    AND i.i_brand = 'Brand#45'
    AND w.w_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND t_sold.t_am_pm = 'PM'
    AND ib.ib_lower_bound >= 30000
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    i.i_category,
    w.w_state
HAVING
    SUM(ws.ws_ext_sales_price) > 1000000
    AND COUNT(DISTINCT p.p_promo_sk) >= 2
ORDER BY
    total_sales DESC
LIMIT 100
