WITH ws_sample AS (
    SELECT * FROM web_sales TABLESAMPLE BERNOULLI (10)
)
(
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        CASE WHEN ws.ws_ext_sales_price > 5000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM ws_sample ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND i.i_category = 'Electronics'
)
INTERSECT
(
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS sales_category
    FROM ws_sample ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_channel_catalog = 'N'
      AND i.i_category = 'Electronics'
)
LIMIT 100
