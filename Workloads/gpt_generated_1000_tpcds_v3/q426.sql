/* Goal: Compute total store profit, web profit, and catalog return loss aggregated by promotion, ship mode, return reason, catalog department, web page type, and customer income band, while linking all 12 selected TPC‑DS tables and reusing dimension tables under multiple aliases. */
WITH ss AS (
    SELECT
        ss_sold_date_sk,
        ss_ticket_number,
        ss_item_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_promo_sk,
        ss_quantity,
        ss_net_profit
    FROM store_sales
    WHERE ss_quantity > 0
),
ws AS (
    SELECT
        ws_sold_date_sk,
        ws_order_number,
        ws_item_sk,
        ws_bill_customer_sk,
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk,
        ws_ship_mode_sk,
        ws_warehouse_sk,
        ws_web_page_sk,
        ws_promo_sk,
        ws_quantity,
        ws_net_profit
    FROM web_sales
    WHERE ws_quantity > 0
),
cr AS (
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_item_sk,
        cr_refunded_customer_sk,
        cr_refunded_cdemo_sk,
        cr_refunded_hdemo_sk,
        cr_returning_customer_sk,
        cr_returning_cdemo_sk,
        cr_returning_hdemo_sk,
        cr_catalog_page_sk,
        cr_ship_mode_sk,
        cr_warehouse_sk,
        cr_reason_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_net_loss,
        cr_order_number
    FROM catalog_returns
    WHERE cr_return_amount > 0
)
SELECT
    p_ss.p_promo_id            AS promo_id,
    p_ss.p_promo_name          AS promo_name,
    sm_ws.sm_type              AS ship_mode_type,
    r.r_reason_desc            AS return_reason,
    cp.cp_department           AS catalog_department,
    wp.wp_type                 AS web_page_type,
    ib.ib_lower_bound          AS income_lower,
    ib.ib_upper_bound          AS income_upper,
    SUM(ss.ss_net_profit)      AS total_store_profit,
    SUM(ws.ws_net_profit)      AS total_web_profit,
    SUM(cr.cr_net_loss)        AS total_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number)  AS web_transactions,
    COUNT(DISTINCT cr.cr_order_number)  AS return_transactions
FROM ss
JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = cd_ss.cd_demo_sk
   AND ws.ws_bill_hdemo_sk = hd_ss.hd_demo_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_cdemo_sk = cd_ss.cd_demo_sk
   AND cr.cr_refunded_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_demographics cd_cr_returning
    ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
JOIN household_demographics hd_cr_returning
    ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN income_band ib
    ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
WHERE p_ss.p_response_target = 1
  AND EXISTS (
        SELECT 1
        FROM promotion p_sub
        WHERE p_sub.p_promo_id = p_ss.p_promo_id
          AND p_sub.p_channel_email = 'N'
      )
GROUP BY
    p_ss.p_promo_id,
    p_ss.p_promo_name,
    sm_ws.sm_type,
    r.r_reason_desc,
    cp.cp_department,
    wp.wp_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_store_profit DESC
LIMIT 100
