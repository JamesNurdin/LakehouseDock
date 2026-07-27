WITH filtered_sales AS (
    SELECT DISTINCT
        ws_order_number,
        ws_ext_sales_price,
        ws_net_profit,
        ws_quantity,
        ws_ship_mode_sk,
        ws_web_site_sk,
        ws_bill_addr_sk,
        ws_ship_addr_sk
    FROM web_sales
    WHERE ws_ext_sales_price > 500
      AND ws_quantity >= 2
      AND ws_ext_sales_price < 2000
      AND ws_net_profit IS NOT NULL
      AND ws_ship_mode_sk IS NOT NULL
)
SELECT
    sm.sm_type AS ship_mode_type,
    ws.web_mkt_class,
    ca_bill.ca_state,
    SUM(fs.ws_ext_sales_price) AS total_sales,
    AVG(fs.ws_net_profit) AS avg_profit,
    COUNT(DISTINCT fs.ws_order_number) AS distinct_orders,
    MAX(fs.ws_ext_sales_price) AS max_sale,
    CASE
        WHEN AVG(fs.ws_net_profit) / NULLIF(SUM(fs.ws_ext_sales_price), 0) > 0.2 THEN 'High Margin'
        ELSE 'Standard Margin'
    END AS profit_category
FROM filtered_sales fs
JOIN ship_mode sm
    ON fs.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site ws
    ON fs.ws_web_site_sk = ws.web_site_sk
JOIN customer_address ca_bill
    ON fs.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON fs.ws_ship_addr_sk = ca_ship.ca_address_sk
WHERE ws.web_rec_end_date > DATE '2000-01-01'
  AND ws.web_mkt_class LIKE '%Broad%'
  AND ca_bill.ca_state = 'CA'
  AND ca_bill.ca_zip IN ('98579', '77752')
  AND ca_ship.ca_state = 'CA'
GROUP BY
    sm.sm_type,
    ws.web_mkt_class,
    ca_bill.ca_state
ORDER BY total_sales DESC
LIMIT 100
