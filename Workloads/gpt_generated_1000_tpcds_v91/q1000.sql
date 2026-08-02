WITH joined_data AS (
    SELECT
        S.s_store_id,
        S.s_state,
        S.s_number_employees,
        P.p_promo_id,
        P.p_discount_active,
        CC.cc_country,
        W.w_state,
        I.inv_quantity_on_hand,
        SS.ss_net_profit,
        CS.cs_net_profit,
        WS.ws_net_profit,
        SR.sr_net_loss,
        CR.cr_net_loss,
        SS.ss_quantity,
        CS.cs_quantity,
        WS.ws_quantity
    FROM customer_demographics CD
    JOIN store_sales SS ON SS.ss_cdemo_sk = CD.cd_demo_sk
    JOIN store S ON SS.ss_store_sk = S.s_store_sk
    JOIN promotion P ON SS.ss_promo_sk = P.p_promo_sk
    JOIN customer_address CA ON SS.ss_addr_sk = CA.ca_address_sk
    JOIN store_returns SR ON SR.sr_ticket_number = SS.ss_ticket_number
    JOIN reason R ON SR.sr_reason_sk = R.r_reason_sk
    JOIN catalog_sales CS ON CS.cs_bill_cdemo_sk = CD.cd_demo_sk
    JOIN call_center CC ON CS.cs_call_center_sk = CC.cc_call_center_sk
    JOIN ship_mode SM ON CS.cs_ship_mode_sk = SM.sm_ship_mode_sk
    JOIN warehouse W ON CS.cs_warehouse_sk = W.w_warehouse_sk
    JOIN catalog_returns CR ON CR.cr_order_number = CS.cs_order_number
    JOIN inventory I ON I.inv_warehouse_sk = W.w_warehouse_sk
    JOIN web_sales WS ON WS.ws_bill_cdemo_sk = CD.cd_demo_sk
    JOIN web_page WP ON WS.ws_web_page_sk = WP.wp_web_page_sk
    JOIN web_site WEB ON WS.ws_web_site_sk = WEB.web_site_sk
    WHERE
        S.s_state = 'CA'
        AND P.p_discount_active = 'Y'
        AND CC.cc_country = 'United States'
        AND W.w_state = 'CA'
        AND I.inv_quantity_on_hand > 0
        AND SS.ss_quantity > 0
        AND WS.ws_quantity > 0
),
agg_by_store_promo AS (
    SELECT
        s_store_id,
        p_promo_id,
        SUM(ss_net_profit) AS store_sales_net_profit,
        SUM(cs_net_profit) AS catalog_sales_net_profit,
        SUM(ws_net_profit) AS web_sales_net_profit,
        SUM(sr_net_loss) AS store_returns_net_loss,
        SUM(cr_net_loss) AS catalog_returns_net_loss,
        SUM(ss_quantity) AS store_quantity,
        SUM(cs_quantity) AS catalog_quantity,
        SUM(ws_quantity) AS web_quantity
    FROM joined_data
    GROUP BY s_store_id, p_promo_id
),
store_summary AS (
    SELECT
        s_store_id,
        SUM(store_sales_net_profit + catalog_sales_net_profit + web_sales_net_profit
            - store_returns_net_loss - catalog_returns_net_loss) AS total_net_profit,
        SUM(store_quantity + catalog_quantity + web_quantity) AS total_quantity
    FROM agg_by_store_promo
    GROUP BY s_store_id
    HAVING SUM(store_sales_net_profit + catalog_sales_net_profit + web_sales_net_profit
            - store_returns_net_loss - catalog_returns_net_loss) > 10000
),
high_profit_stores AS (
    SELECT s_store_id FROM store_summary WHERE total_net_profit > 50000
),
low_profit_stores AS (
    SELECT s_store_id FROM store_summary WHERE total_net_profit < 20000
)
SELECT
    ss.s_store_id,
    ss.total_net_profit,
    ss.total_quantity
FROM store_summary ss
WHERE ss.s_store_id IN (
    SELECT s_store_id FROM high_profit_stores
    EXCEPT
    SELECT s_store_id FROM low_profit_stores
)
ORDER BY ss.total_net_profit DESC
LIMIT 100
