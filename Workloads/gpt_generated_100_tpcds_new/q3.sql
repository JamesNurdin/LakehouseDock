(
    SELECT c.c_customer_id
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND i.i_product_name LIKE '%Brush%'
    GROUP BY c.c_customer_id
    HAVING count(*) >= 2
)
INTERSECT
(
    SELECT c.c_customer_id
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '^A.*[0-9]$')
      AND concat(c.c_salutation, ' ', c.c_first_name) LIKE '%Mr.%'
    GROUP BY c.c_customer_id
    HAVING sum(wr.wr_return_amt) > 50
)
LIMIT 100
