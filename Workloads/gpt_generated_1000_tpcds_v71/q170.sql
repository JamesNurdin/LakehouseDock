WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number
    FROM store_sales ss
)
SELECT
    d.d_year,
    i.i_category,
    p.p_promo_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    sm.sm_type,
    w.w_warehouse_name,
    SUM(base.ss_ext_sales_price) AS total_sales,
    AVG(base.ss_net_profit) AS avg_profit,
    COUNT(DISTINCT base.ss_ticket_number) AS distinct_tickets,
    MIN(base.ss_quantity) AS min_qty,
    MAX(base.ss_quantity) AS max_qty
FROM base
JOIN date_dim d ON base.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON base.ss_sold_time_sk = t.t_time_sk
JOIN item i ON base.ss_item_sk = i.i_item_sk
JOIN promotion p ON base.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON base.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON base.ss_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_date_sk = d.d_date_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE d.d_year = 2001
  AND i.i_current_price > 50.00
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY
    d.d_year,
    i.i_category,
    p.p_promo_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    sm.sm_type,
    w.w_warehouse_name
ORDER BY total_sales DESC
LIMIT 100
