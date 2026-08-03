WITH sr_full AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        sr.sr_returned_date_sk,
        sr.sr_customer_sk,
        sr.sr_addr_sk,
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_return_tax
    FROM store s
    FULL OUTER JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
)
SELECT
    d.d_year,
    sr_full.s_state,
    cc.cc_market_manager,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT sr_full.sr_ticket_number) AS distinct_returns,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(sr_full.sr_return_amt) AS total_return_amount,
    AVG(cs.cs_quantity) AS avg_quantity,
    MIN(cs.cs_ext_discount_amt) AS min_discount,
    MAX(sr_full.sr_return_tax) AS max_return_tax
FROM sr_full
JOIN date_dim d
    ON sr_full.sr_returned_date_sk = d.d_date_sk
JOIN customer c
    ON sr_full.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON sr_full.sr_addr_sk = ca.ca_address_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
   AND cs.cs_bill_customer_sk = c.c_customer_sk
   AND cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
   AND i.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
  AND sr_full.s_state = 'CA'
  AND i.inv_quantity_on_hand > 1000
  AND cs.cs_quantity > 5
  AND cs.cs_call_center_sk IN (
        SELECT cc2.cc_call_center_sk
        FROM call_center cc2
        WHERE cc2.cc_class = 'large'
    )
GROUP BY d.d_year, sr_full.s_state, cc.cc_market_manager
ORDER BY total_net_paid DESC
OFFSET 0 LIMIT 100
