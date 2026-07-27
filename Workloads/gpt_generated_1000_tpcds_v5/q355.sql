WITH filtered AS (
    SELECT
        cc.cc_state,
        ca.ca_state,
        cs.cs_order_number,
        cs.cs_net_paid,
        ws.ws_order_number,
        ws.ws_net_paid
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    WHERE cc.cc_city = 'Harmony'
      AND cc.cc_sq_ft > 300000000
      AND ca.ca_street_number = '819'
      AND ca.ca_city = 'Glendale'
      AND p.p_discount_active = 'Y'
      AND cs.cs_wholesale_cost > 50
      AND ws.ws_net_paid > 1000
)
SELECT
    cc_state,
    ca_state,
    SUM(cs_net_paid) AS catalog_sales_total,
    SUM(ws_net_paid) AS web_sales_total,
    COUNT(DISTINCT cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws_order_number) AS web_orders
FROM filtered
GROUP BY GROUPING SETS (
    (cc_state, ca_state),
    (cc_state),
    (ca_state),
    ()
)
ORDER BY catalog_sales_total DESC
LIMIT 100
