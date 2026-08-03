WITH sales_enriched AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_quantity,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_bill_addr_sk,
        i.i_category,
        i.i_product_name,
        i.i_item_desc,
        p.p_channel_demo,
        ca.ca_city,
        ca.ca_state
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_product_name, '^a.*')
      AND regexp_like(ca.ca_city, '^A.*')
      AND p.p_channel_demo = 'N'
)
SELECT
    s.i_category,
    concat(s.ca_city, ', ', s.ca_state) AS city_state,
    regexp_extract(s.i_item_desc, '(\\w+)', 1) AS first_word_desc,
    sum(s.ws_ext_sales_price) AS total_sales,
    avg(s.ws_ext_discount_amt) AS avg_discount,
    count(DISTINCT s.ws_order_number) AS distinct_orders
FROM sales_enriched s
GROUP BY
    s.i_category,
    concat(s.ca_city, ', ', s.ca_state),
    regexp_extract(s.i_item_desc, '(\\w+)', 1)
ORDER BY total_sales DESC
LIMIT 100
