WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_item_sk
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_profit > 0
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
)
SELECT
    cc.cc_name,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_profit,
    sm.sm_carrier,
    ca_bill.ca_city AS bill_city,
    ca_ship.ca_city AS ship_city,
    cr.cr_return_amount,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY cs.cs_net_profit DESC) AS profit_rank
FROM filtered_sales cs
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
WHERE cc.cc_employees >= 100
  AND sm.sm_carrier = 'DHL'
  AND ca_bill.ca_state = 'CA'
  AND ca_ship.ca_state = 'NY'
  AND EXISTS (
        SELECT 1
        FROM tpcds.promotion p
        WHERE p.p_promo_sk = cs.cs_promo_sk
          AND p.p_channel_email = 'Y'
          AND p.p_discount_active = 'Y'
      )
ORDER BY profit_rank
LIMIT 100
