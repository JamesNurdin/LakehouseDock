WITH base_sales AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        i.i_item_sk,
        i.i_category_id,
        c.c_customer_sk,
        hd.hd_demo_sk,
        p.p_promo_sk,
        p.p_promo_id
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON i.i_item_sk = ss.ss_item_sk
    JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
    JOIN promotion p ON p.p_promo_sk = ss.ss_promo_sk
)
SELECT
    cp.cp_department,
    bs.d_year,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    SUM(cr.cr_net_loss * -1) AS catalog_return_gain,
    CASE
        WHEN SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss) > 100000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS profit_level
FROM base_sales bs
JOIN store_returns sr
    ON sr.sr_ticket_number = bs.ss_ticket_number
   AND sr.sr_returned_date_sk = bs.d_date_sk
   AND sr.sr_item_sk = bs.i_item_sk
JOIN store_sales ss
    ON ss.ss_ticket_number = bs.ss_ticket_number
JOIN web_sales ws
    ON ws.ws_item_sk = bs.i_item_sk
   AND ws.ws_sold_date_sk = bs.d_date_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = bs.i_item_sk
   AND cr.cr_returned_date_sk = bs.d_date_sk
JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cr.cr_warehouse_sk
JOIN promotion p_ws
    ON p_ws.p_promo_sk = ws.ws_promo_sk
JOIN customer c_refunded
    ON c_refunded.c_customer_sk = cr.cr_refunded_customer_sk
GROUP BY cp.cp_department, bs.d_year
ORDER BY profit_level DESC, bs.d_year
LIMIT 100
