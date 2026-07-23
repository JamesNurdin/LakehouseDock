WITH catalog_sales_agg AS (
    SELECT
        cs_order_number,
        cs_item_sk,
        cs_bill_customer_sk,
        cs_bill_addr_sk,
        cs_ship_customer_sk,
        cs_ship_addr_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_promo_sk,
        SUM(cs_ext_sales_price) AS total_ext_sales_price,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit
    FROM catalog_sales
    WHERE cs_quantity >= 5
    GROUP BY
        cs_order_number,
        cs_item_sk,
        cs_bill_customer_sk,
        cs_bill_addr_sk,
        cs_ship_customer_sk,
        cs_ship_addr_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_promo_sk
)
SELECT
    cs.cs_order_number AS catalog_order_number,
    cs.cs_item_sk AS catalog_item_sk,
    cp.cp_department,
    cp.cp_catalog_page_number,
    sm.sm_carrier,
    p.p_promo_name,
    cs.total_ext_sales_price,
    cs.total_quantity,
    cs.total_net_profit,
    RANK() OVER (ORDER BY cs.total_net_profit DESC) AS catalog_profit_rank,
    ws.ws_order_number AS web_order_number,
    ws.ws_item_sk AS web_item_sk,
    wsite.web_name,
    ws.ws_ext_sales_price,
    ws.ws_quantity,
    ws.ws_net_paid,
    ROW_NUMBER() OVER (PARTITION BY wsite.web_site_id ORDER BY ws.ws_net_paid DESC) AS web_sales_rank
FROM catalog_sales_agg cs
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
LEFT JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
LEFT JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
LEFT JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
LEFT JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
LEFT JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer c_ws_ship ON ws.ws_ship_customer_sk = c_ws_ship.c_customer_sk
JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE
    sm.sm_carrier = 'UPS'
    AND wsite.web_mkt_id = 5
    AND cp.cp_department = 'Electronics'
    AND cs.total_ext_sales_price > 1000
    AND ws.ws_quantity >= 5
ORDER BY catalog_profit_rank
LIMIT 100
