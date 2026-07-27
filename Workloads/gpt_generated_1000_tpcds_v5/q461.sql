WITH sr_agg AS (
    SELECT
        sr.sr_returned_date_sk AS d_date_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        ca.ca_state AS return_state,
        sr.sr_customer_sk
    FROM store_returns sr
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_amt > 100
)
SELECT
    d.d_year,
    cp.cp_department,
    ws.web_manager,
    ca_bill.ca_state AS bill_state,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS dept_sales_rank,
    CASE
        WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High'
        WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    AVG(sr_agg.sr_return_amt) AS avg_return_amount
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN sr_agg ON d.d_date_sk = sr_agg.d_date_sk
WHERE d.d_year = 2001
  AND cp.cp_department = 'Books'
  AND ws.web_manager = 'James Austin'
  AND ca_bill.ca_state = 'CA'
  AND EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_returned_date_sk = d.d_date_sk
          AND sr2.sr_return_amt > 200
      )
GROUP BY d.d_year, cp.cp_department, ws.web_manager, ca_bill.ca_state
ORDER BY total_sales DESC
LIMIT 100
