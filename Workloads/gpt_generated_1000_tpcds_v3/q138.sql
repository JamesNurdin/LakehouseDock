WITH high_cost_promos AS (
    SELECT p_promo_sk, p_promo_name, p_cost
    FROM promotion
    WHERE p_cost > 10000
)
SELECT
    cc.cc_company_name,
    hp.p_promo_name,
    wsite.web_name,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_paid) / (SELECT SUM(ws2.ws_net_paid) FROM web_sales ws2) AS net_paid_share
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN web_sales ws ON ws.ws_bill_addr_sk = ca_refunded.ca_address_sk
JOIN high_cost_promos hp ON ws.ws_promo_sk = hp.p_promo_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
GROUP BY
    cc.cc_company_name,
    hp.p_promo_name,
    wsite.web_name
ORDER BY total_net_paid DESC
LIMIT 100
