WITH customer_returns AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_return_time_sk,
        c.c_first_name AS return_customer_first_name,
        c.c_last_name AS return_customer_last_name,
        ca.ca_city AS return_customer_city,
        hd.hd_buy_potential AS return_buy_potential,
        r.r_reason_desc AS return_reason_desc
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_return_amt > 100
      AND hd.hd_buy_potential = '>10000'
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_sold_time_sk,
    ws_time.t_hour,
    i_ws.i_item_id,
    i_ws.i_product_name,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    p.p_promo_name,
    cust_ws.c_first_name,
    cust_ws.c_last_name,
    ca_ws.ca_city,
    CASE WHEN ws.ws_ext_sales_price > 500 THEN 'High' ELSE 'Normal' END AS sales_price_category,
    ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank,
    (SELECT MAX(s2.sr_return_amt) FROM store_returns s2 WHERE s2.sr_item_sk = ws.ws_item_sk) AS max_return_amt_for_item,
    cr.sr_return_amt,
    CASE WHEN cr.sr_return_amt IS NOT NULL THEN 1 ELSE 0 END AS has_recent_return,
    inv.inv_quantity_on_hand
FROM web_sales ws
JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN customer cust_ws ON ws.ws_bill_customer_sk = cust_ws.c_customer_sk
LEFT JOIN customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
LEFT JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
LEFT JOIN inventory inv ON inv.inv_item_sk = i_ws.i_item_sk
LEFT JOIN time_dim ws_time ON ws.ws_sold_time_sk = ws_time.t_time_sk
LEFT JOIN customer_returns cr ON cr.sr_item_sk = ws.ws_item_sk
WHERE inv.inv_quantity_on_hand > 0
  AND ws.ws_ext_sales_price > 20
  AND ws_time.t_hour BETWEEN 8 AND 20
ORDER BY ws.ws_ext_sales_price DESC
LIMIT 100
