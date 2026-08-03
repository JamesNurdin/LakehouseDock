WITH filtered_sales AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_net_profit AS net_profit,
        i.i_brand AS brand,
        i.i_item_desc AS item_desc,
        p.p_promo_name AS promo_name,
        regexp_extract(i.i_item_desc, '(\\d{4})', 1) AS four_digit_code
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
      AND c.c_email_address LIKE '%@example.com'
      AND regexp_like(p.p_promo_name, '^Discount')
)
SELECT
    brand,
    four_digit_code,
    promo_name,
    COUNT(DISTINCT order_number) AS orders,
    SUM(net_profit) AS total_profit,
    CASE WHEN SUM(net_profit) > 20000 THEN 'High' ELSE 'Medium' END AS profit_category
FROM filtered_sales
GROUP BY brand, four_digit_code, promo_name
HAVING SUM(net_profit) > 5000
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
