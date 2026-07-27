WITH sales_enriched AS (
   SELECT
       cs.cs_order_number,
       cs.cs_sales_price,
       cs.cs_quantity,
       cs.cs_net_paid,
       cs.cs_ext_ship_cost,
       cs.cs_ship_mode_sk,
       cs.cs_promo_sk,
       sm.sm_code,
       sm.sm_type,
       sm.sm_contract,
       p.p_channel_tv,
       p.p_channel_press,
       p.p_discount_active,
       ca_bill.ca_state AS bill_state,
       ca_ship.ca_state AS ship_state
   FROM catalog_sales cs
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
   JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
   WHERE sm.sm_code IN ('AIR', 'SEA')
     AND sm.sm_contract LIKE 'A%'
     AND p.p_channel_tv = 'Y'
     AND p.p_channel_press = 'N'
     AND cs.cs_sales_price > 20
)
SELECT
    se.cs_order_number,
    se.cs_sales_price,
    se.cs_quantity,
    se.cs_net_paid,
    se.sm_code,
    se.bill_state,
    se.ship_state,
    CASE
        WHEN se.cs_quantity >= 10 THEN 'Bulk'
        WHEN se.cs_quantity BETWEEN 5 AND 9 THEN 'Medium'
        ELSE 'Small'
    END AS quantity_category,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS avg_active_promo_cost,
    RANK() OVER (PARTITION BY se.sm_code ORDER BY se.cs_net_paid DESC) AS net_paid_rank,
    SUM(se.cs_ext_ship_cost) OVER (PARTITION BY se.sm_code ORDER BY se.cs_net_paid DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_ship_cost
FROM sales_enriched se
ORDER BY se.cs_net_paid DESC, se.cs_order_number
LIMIT 100
