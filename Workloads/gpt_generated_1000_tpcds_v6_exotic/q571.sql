WITH distinct_promos AS (
    SELECT DISTINCT p.p_promo_name, p.p_channel_email
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
)
SELECT
    CASE WHEN GROUPING(p.p_channel_email) = 1 THEN 'ALL Channels' ELSE p.p_channel_email END AS promo_channel,
    CASE WHEN GROUPING(wsit.web_manager) = 1 THEN 'ALL Managers' ELSE wsit.web_manager END AS web_manager,
    SUM(cs.cs_net_paid)                     AS total_catalog_sales,
    SUM(ws.ws_net_paid)                     AS total_web_sales,
    SUM(sr.sr_return_amt)                  AS total_store_returns,
    SUM(wr.wr_return_amt)                  AS total_web_returns,
    SUM(inv.inv_quantity_on_hand)          AS total_inventory_on_hand,
    (SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid) - SUM(sr.sr_return_amt) - SUM(wr.wr_return_amt)) AS net_revenue
FROM catalog_sales cs
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN distinct_promos dp ON dp.p_promo_name = p.p_promo_name
JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
                 AND cs.cs_promo_sk = ws.ws_promo_sk
JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
                        AND sr.sr_customer_sk = c_bill.c_customer_sk
JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                       AND wr.wr_item_sk = i.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_item_sk = cs.cs_item_sk
      AND sr2.sr_customer_sk = cs.cs_bill_customer_sk
      AND sr2.sr_return_quantity > 0
)
GROUP BY GROUPING SETS (
    (p.p_channel_email, wsit.web_manager),
    (p.p_channel_email),
    (wsit.web_manager),
    ()
)
HAVING (SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid) - SUM(sr.sr_return_amt) - SUM(wr.wr_return_amt)) > 1000
ORDER BY net_revenue DESC
LIMIT 100
