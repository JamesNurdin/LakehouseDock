WITH filtered_sales AS (
    SELECT
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_ship_date_sk,
        ws_item_sk,
        ws_bill_customer_sk,
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk,
        ws_bill_addr_sk,
        ws_ship_customer_sk,
        ws_ship_cdemo_sk,
        ws_ship_hdemo_sk,
        ws_ship_addr_sk,
        ws_web_page_sk,
        ws_web_site_sk,
        ws_ship_mode_sk,
        ws_warehouse_sk,
        ws_promo_sk,
        ws_order_number,
        ws_quantity,
        ws_wholesale_cost,
        ws_list_price,
        ws_sales_price,
        ws_ext_discount_amt,
        ws_ext_sales_price,
        ws_ext_wholesale_cost,
        ws_ext_list_price,
        ws_ext_tax,
        ws_coupon_amt,
        ws_ext_ship_cost,
        ws_net_paid,
        ws_net_paid_inc_tax,
        ws_net_paid_inc_ship,
        ws_net_paid_inc_ship_tax,
        ws_net_profit
    FROM web_sales
    WHERE ws_ext_wholesale_cost BETWEEN 500 AND 3000
      AND ws_quantity >= 2
      AND ws_ext_tax > 20
      AND ws_net_paid_inc_ship < 4000
      AND ws_ship_mode_sk = 1
)
SELECT
    ca.ca_state,
    ca.ca_city,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid_inc_ship) AS total_net_paid_inc_ship,
    AVG(ws.ws_ext_tax) AS avg_tax,
    MIN(ws.ws_ext_wholesale_cost) AS min_wholesale_cost,
    MAX(ws.ws_ext_wholesale_cost) AS max_wholesale_cost
FROM filtered_sales ws
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE ca.ca_country = 'United States'
  AND ca.ca_gmt_offset = -5.00
  AND ca.ca_city = 'New York'
GROUP BY ca.ca_state, ca.ca_city
ORDER BY total_net_paid_inc_ship DESC
LIMIT 10
