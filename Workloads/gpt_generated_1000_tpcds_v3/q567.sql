WITH filtered_items AS (
    SELECT i_item_sk,
           i_product_name,
           CASE WHEN regexp_like(i_product_name, '[0-9]{3}') THEN regexp_extract(i_product_name, '([0-9]{3})', 1) ELSE NULL END AS product_code
    FROM item
    WHERE regexp_like(i_product_name, '^[A-Za-z]+[0-9]{3}')
)
SELECT
    ca.ca_state,
    fi.product_code,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_net_loss) AS avg_net_loss,
    CASE WHEN SUM(sr.sr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
FROM store_returns sr
JOIN store_sales ss
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN filtered_items fi
    ON sr.sr_item_sk = fi.i_item_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
JOIN time_dim td
    ON sr.sr_return_time_sk = td.t_time_sk
WHERE ca.ca_state IS NOT NULL
  AND td.t_hour BETWEEN 8 AND 20
  AND EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_customer_sk = sr.sr_customer_sk
          AND c.c_email_address LIKE '%@gmail.com'
    )
GROUP BY ca.ca_state, fi.product_code
ORDER BY total_net_loss DESC
LIMIT 100
