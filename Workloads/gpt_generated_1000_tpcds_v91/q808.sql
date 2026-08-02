WITH high_discount_items AS (
    SELECT DISTINCT i.i_item_sk, i.i_item_id, i.i_product_name
    FROM item i
    WHERE i.i_current_price > 100
),
combined_sales AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_ext_discount_amt AS discount_amt,
        (
            SELECT SUM(ss2.ss_ext_discount_amt)
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = c.c_customer_sk
        ) AS total_customer_discount,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN high_discount_items i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_ext_discount_amt > 100
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
      )
    UNION ALL
    SELECT
        c.c_customer_id,
        i.i_item_id,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_ext_discount_amt AS discount_amt,
        (
            SELECT SUM(ws2.ws_ext_discount_amt)
            FROM web_sales ws2
            WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
        ) AS total_customer_discount,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN high_discount_items i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_ext_discount_amt > 100
)
SELECT DISTINCT
    cs.c_customer_id,
    cs.i_item_id,
    cs.sold_date_sk,
    cs.discount_amt,
    cs.total_customer_discount,
    cs.sales_channel
FROM combined_sales cs
ORDER BY cs.total_customer_discount DESC
LIMIT 100
