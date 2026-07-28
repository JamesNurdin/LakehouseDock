/* goal: Rank catalog sales by net paid per company and flag high‑price orders that have associated returns, limited to specific market managers, company IDs, ship dates, price ranges and address characteristics. */
WITH sales_with_cc AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_order_number,
        cs.cs_ext_list_price,
        cs.cs_net_paid_inc_ship,
        cs.cs_quantity,
        cs.cs_call_center_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cc.cc_company,
        cc.cc_market_manager,
        cc.cc_mkt_id
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_company IN (1, 2, 3, 4, 6)
      AND cc.cc_mkt_id BETWEEN 1 AND 6
      AND cc.cc_market_manager LIKE '%Smith%'
)
SELECT
    s.cs_order_number,
    s.cs_ship_date_sk,
    s.cs_ext_list_price,
    s.cs_net_paid_inc_ship,
    ca_bill.ca_street_type,
    ca_bill.ca_location_type,
    COALESCE(wr.wr_return_amt, 0) AS return_amount,
    RANK() OVER (PARTITION BY s.cc_company ORDER BY s.cs_net_paid_inc_ship DESC) AS revenue_rank,
    ROW_NUMBER() OVER (ORDER BY s.cs_ext_list_price DESC) AS price_rownum,
    CASE WHEN wr.wr_return_amt > 0 THEN 'Returned' ELSE 'No Return' END AS return_flag,
    s.cc_company
FROM sales_with_cc s
JOIN customer_address ca_bill
    ON s.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON s.cs_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN web_returns wr
    ON ca_bill.ca_address_sk = wr.wr_refunded_addr_sk
WHERE s.cs_ship_date_sk BETWEEN 2450840 AND 2450905
  AND s.cs_ext_list_price > 500
  AND ca_bill.ca_street_type IN ('Boulevard', 'Street')
  AND ca_bill.ca_location_type = 'single family'
  AND s.cs_quantity > 1
  AND (wr.wr_return_amt IS NULL OR wr.wr_return_amt < 1000)
ORDER BY revenue_rank ASC
LIMIT 100
