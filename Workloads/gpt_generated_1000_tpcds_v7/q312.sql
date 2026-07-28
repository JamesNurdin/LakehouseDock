WITH segment_a AS (
        SELECT c.c_customer_id,
               SUM(sr.sr_return_amt) AS total_return,
               COUNT(sr.sr_ticket_number) AS return_cnt,
               SUM(wp.wp_char_count) AS total_chars,
               COUNT(wp.wp_web_page_sk) AS page_cnt
        FROM customer c
        JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
        WHERE c.c_birth_month <= 6
          AND sr.sr_fee > 30
        GROUP BY c.c_customer_id
    ),
    segment_b AS (
        SELECT c.c_customer_id,
               SUM(sr.sr_return_amt) AS total_return,
               COUNT(sr.sr_ticket_number) AS return_cnt,
               SUM(wp.wp_char_count) AS total_chars,
               COUNT(wp.wp_web_page_sk) AS page_cnt
        FROM customer c
        JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
        WHERE c.c_birth_month > 6
          AND sr.sr_fee <= 30
        GROUP BY c.c_customer_id
    )
SELECT * FROM segment_a
UNION ALL
SELECT * FROM segment_b
ORDER BY total_return DESC
