WITH sales_aggregated AS (
    SELECT
        s.s_state,
        s.s_store_name,
        cp.cp_department,
        p2.p_promo_name,
        SUM(ss.ss_net_paid) AS store_sales_net_paid,
        SUM(ss.ss_net_profit) AS store_sales_net_profit,
        SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
        SUM(cs.cs_net_profit) AS catalog_sales_net_profit,
        SUM(ws.ws_net_paid) AS web_sales_net_paid,
        SUM(ws.ws_net_profit) AS web_sales_net_profit,
        SUM(sr.sr_net_loss) AS store_returns_net_loss,
        SUM(wr.wr_net_loss) AS web_returns_net_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS num_web_transactions
    FROM
        customer_address ca
        JOIN store_sales ss ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p1 ON ss.ss_promo_sk = p1.p_promo_sk
        LEFT JOIN store_returns sr
            ON sr.sr_addr_sk = ca.ca_address_sk
            AND sr.sr_store_sk = s.s_store_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN catalog_sales cs ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm_c ON cs.cs_ship_mode_sk = sm_c.sm_ship_mode_sk
        JOIN warehouse w_c ON cs.cs_warehouse_sk = w_c.w_warehouse_sk
        JOIN promotion p2 ON cs.cs_promo_sk = p2.p_promo_sk
        JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN ship_mode sm_w ON ws.ws_ship_mode_sk = sm_w.sm_ship_mode_sk
        JOIN warehouse w_w ON ws.ws_warehouse_sk = w_w.w_warehouse_sk
        JOIN promotion p3 ON ws.ws_promo_sk = p3.p_promo_sk
        LEFT JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = ws.ws_item_sk
            AND wr.wr_refunded_addr_sk = ca.ca_address_sk
            AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        ca.ca_state = 'CA'
        AND ca.ca_city IN ('Springfield', 'Fairview')
        AND cc.cc_state = 'TX'
        AND s.s_state = 'WA'
        AND cp.cp_type = 'ELIGIBLE'
        AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
        AND p2.p_discount_active = 'Y'
    GROUP BY
        ROLLUP(s.s_state, s.s_store_name, cp.cp_department, p2.p_promo_name)
)
SELECT
    s_state,
    s_store_name,
    cp_department,
    p_promo_name,
    store_sales_net_paid,
    store_sales_net_profit,
    catalog_sales_net_paid,
    web_sales_net_paid,
    store_returns_net_loss,
    web_returns_net_loss,
    CASE
        WHEN store_sales_net_paid > 100000 THEN 'HIGH'
        WHEN store_sales_net_paid > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_volume_category,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY store_sales_net_paid DESC) AS rn_state_sales
FROM
    sales_aggregated
ORDER BY
    s_state,
    rn_state_sales
LIMIT 100
