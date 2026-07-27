WITH sales_filtered AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_net_profit,
        ws.ws_net_paid_inc_tax,
        ws.ws_promo_sk,
        d.d_year,
        i.i_item_desc,
        p.p_promo_name,
        regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS three_digit_seq
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2022
      AND regexp_like(i.i_item_desc, '\\d{3}')
      AND ca.ca_city LIKE 'W%'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND d.d_date_sk BETWEEN p2.p_start_date_sk AND p2.p_end_date_sk
      )
)
SELECT
    d_year,
    p_promo_name,
    three_digit_seq,
    COUNT(*) AS sales_cnt,
    SUM(ws_net_profit) AS total_profit,
    AVG(ws_net_paid_inc_tax) AS avg_paid
FROM sales_filtered
GROUP BY d_year, p_promo_name, three_digit_seq
ORDER BY total_profit DESC
LIMIT 100
