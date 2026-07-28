/* goal: Analyze profitability and loss across catalog sales, web sales, and store returns by state, city, and promotion, applying several selective filters. */
SELECT
    ca.ca_state,
    ca.ca_city,
    p.p_promo_name,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(sr.sr_net_loss) AS store_loss,
    AVG(ws.ws_wholesale_cost) AS avg_ws_wholesale_cost,
    MIN(p.p_cost) AS min_promo_cost,
    MAX(ca.ca_gmt_offset) AS max_gmt_offset
FROM
    catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE
    cs.cs_sold_date_sk BETWEEN 2450 AND 2455
    AND cs.cs_quantity >= 2
    AND ca.ca_state = 'CA'
    AND p.p_channel_radio = 'N'
    AND p.p_discount_active = 'Y'
    AND ws.ws_wholesale_cost > 60.0
    AND ws.ws_ext_ship_cost < 500.0
GROUP BY
    ca.ca_state,
    ca.ca_city,
    p.p_promo_name
ORDER BY
    ca.ca_state,
    ca.ca_city
LIMIT 100
