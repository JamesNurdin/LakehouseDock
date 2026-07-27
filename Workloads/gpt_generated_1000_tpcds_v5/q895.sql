WITH filtered_sales AS (
    SELECT
        ws_sold_time_sk,
        ws_bill_addr_sk,
        ws_order_number,
        ws_quantity,
        ws_ext_sales_price,
        ws_coupon_amt,
        ws_net_paid,
        ws_ext_discount_amt
    FROM web_sales
    WHERE ws_ext_sales_price > 3000
      AND ws_coupon_amt < 500
      AND ws_quantity >= 2
)
SELECT
    ca.ca_city,
    ca.ca_county,
    td.t_hour,
    COUNT(DISTINCT fs.ws_order_number) AS orders,
    SUM(fs.ws_net_paid) AS total_net_paid,
    AVG(fs.ws_ext_discount_amt) AS avg_discount,
    MIN(fs.ws_coupon_amt) AS min_coupon,
    MAX(fs.ws_ext_sales_price) AS max_sales_price
FROM filtered_sales AS fs
JOIN time_dim AS td
    ON fs.ws_sold_time_sk = td.t_time_sk
JOIN customer_address AS ca
    ON fs.ws_bill_addr_sk = ca.ca_address_sk
WHERE ca.ca_county = 'Madison County'
  AND ca.ca_gmt_offset = -6.00
  AND td.t_minute = 13
GROUP BY ca.ca_city, ca.ca_county, td.t_hour
ORDER BY total_net_paid DESC
LIMIT 100
