/* goal: Compare catalog and web sales performance by department, county and brand, applying realistic filters, categorizing profit levels, and showing average web price per item */
WITH ws_item_agg AS (
    SELECT
        ws_item_sk,
        AVG(ws_list_price) AS avg_ws_list_price,
        SUM(ws_ext_discount_amt) AS total_ws_discount
    FROM web_sales
    WHERE ws_ship_hdemo_sk IN (297, 4255, 6964)
      AND ws_list_price BETWEEN 50 AND 200
    GROUP BY ws_item_sk
)
SELECT
    cp.cp_department,
    ca_bill.ca_county,
    i.i_brand,
    COUNT(DISTINCT cs.cs_order_number)               AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number)               AS web_order_cnt,
    SUM(cs.cs_net_paid)                              AS total_catalog_net_paid,
    SUM(ws.ws_net_paid)                              AS total_web_net_paid,
    SUM(cs.cs_ext_discount_amt) + SUM(ws.ws_ext_discount_amt) AS total_discount,
    CASE
        WHEN SUM(cs.cs_net_paid) > 100000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_paid) > 50000  THEN 'MEDIUM'
        ELSE 'LOW'
    END                                            AS catalog_profit_category,
    (
        SELECT AVG(ws2.ws_list_price)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk
          AND ws2.ws_ship_hdemo_sk = 297
    )                                               AS avg_ws_price_for_item
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN customer_address ca_ws_bill
  ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
LEFT JOIN ws_item_agg wsa
  ON wsa.ws_item_sk = i.i_item_sk
WHERE cp.cp_department = 'Books'
  AND ca_bill.ca_county = 'Maricopa County'
  AND i.i_current_price BETWEEN 50 AND 200
  AND cs.cs_bill_customer_sk = 4936748
  AND cs.cs_quantity > 5
GROUP BY
    cp.cp_department,
    ca_bill.ca_county,
    i.i_brand,
    i.i_item_sk
ORDER BY total_catalog_net_paid DESC
LIMIT 100
