WITH ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_quantity,
        ws.ws_web_page_sk,
        ws.ws_bill_addr_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_mode_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_ship_mode_sk IN (2, 7, 12)
      AND ws.ws_web_page_sk IN (
          SELECT wp.wp_web_page_sk
          FROM tpcds.web_page wp
          WHERE wp.wp_type = 'product'
      )
),
sr AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_cdemo_sk,
        sr.sr_addr_sk
    FROM tpcds.store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2453650
)
SELECT
    ca.ca_state,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MIN(ws.ws_quantity) AS min_quantity,
    MAX(ws.ws_quantity) AS max_quantity
FROM ws
JOIN tpcds.customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN sr
    ON sr.sr_addr_sk = ca.ca_address_sk
   AND sr.sr_cdemo_sk = cd.cd_demo_sk
WHERE ca.ca_state = 'TX'
GROUP BY ca.ca_state, wp.wp_type
ORDER BY total_sales DESC
LIMIT 20
