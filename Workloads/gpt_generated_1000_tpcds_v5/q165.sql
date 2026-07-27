WITH item_sales AS (
    SELECT i.i_item_sk,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_rec_end_date > DATE '2000-01-01'
    GROUP BY i.i_item_sk
)
SELECT
    c.c_birth_country AS birth_country,
    ca.ca_state AS state,
    i.i_category AS item_category,
    i.i_size AS item_size,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_ext_sales_price) AS sum_sales,
    AVG(ss.ss_net_profit) AS avg_profit,
    SUM(wr.wr_net_loss) AS total_return_loss,
    MAX(wr.wr_return_amt) AS max_return_amount
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
                     AND wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_birth_country IN ('JORDAN', 'PHILIPPINES')
  AND i.i_size IN ('small', 'extra large')
  AND wr.wr_return_amt > 500
  AND wr.wr_return_tax BETWEEN 20 AND 100
  AND EXISTS (
        SELECT 1
        FROM item_sales isales
        WHERE isales.i_item_sk = i.i_item_sk
          AND isales.total_sales > 10000
    )
GROUP BY c.c_birth_country, ca.ca_state, i.i_category, i.i_size
ORDER BY sum_sales DESC
LIMIT 100
