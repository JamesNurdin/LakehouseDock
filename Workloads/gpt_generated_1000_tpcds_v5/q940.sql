WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cp.cp_catalog_page_number,
        p.p_promo_name,
        sm.sm_code,
        ca.ca_state,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_sales cs
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    WHERE cp.cp_catalog_page_number BETWEEN 5 AND 20
      AND sm.sm_code IN ('AIR', 'SEA')
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'TX'
)
SELECT *
FROM (
    SELECT
        sd.cs_order_number AS order_id,
        sd.cs_bill_customer_sk AS customer_id,
        sd.cp_catalog_page_number AS page_number,
        sd.p_promo_name AS promo,
        sd.sm_code AS ship_mode,
        sd.ca_state,
        sd.cs_net_paid AS sales_amount,
        sd.cs_net_profit,
        CASE WHEN sd.cs_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        RANK() OVER (PARTITION BY sd.ca_state ORDER BY sd.cs_net_profit DESC) AS profit_rank
    FROM sales_data sd
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN customer_address ca3 ON sr.sr_addr_sk = ca3.ca_address_sk
        WHERE sr.sr_customer_sk = sd.cs_bill_customer_sk
          AND ca3.ca_state = 'TX'
    )
) AS a
UNION ALL
SELECT
    sr.sr_ticket_number AS order_id,
    sr.sr_customer_sk AS customer_id,
    NULL AS page_number,
    NULL AS promo,
    NULL AS ship_mode,
    ca2.ca_state,
    sr.sr_return_amt AS sales_amount,
    NULL AS cs_net_profit,
    CASE WHEN sr.sr_return_amt > 500 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY ca2.ca_state ORDER BY sr.sr_return_amt DESC) AS profit_rank
FROM store_returns sr
JOIN customer_address ca2 ON sr.sr_addr_sk = ca2.ca_address_sk
WHERE ca2.ca_state = 'TX'
  AND sr.sr_return_amt > 0
  AND sr.sr_return_quantity >= 1
  AND sr.sr_net_loss IS NOT NULL
ORDER BY ca_state, profit_rank
LIMIT 100
