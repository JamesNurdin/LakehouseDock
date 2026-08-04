WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        COALESCE(ss.ss_ticket_number, sr.sr_ticket_number)                AS ticket_number,
        COALESCE(ss.ss_sold_date_sk, sr.sr_returned_date_sk)             AS date_sk,
        COALESCE(ss.ss_quantity, 0)                                      AS quantity_sold,
        COALESCE(ss.ss_net_paid, 0)                                      AS net_paid,
        COALESCE(ss.ss_net_profit, 0)                                    AS net_profit,
        COALESCE(sr.sr_return_quantity, 0)                               AS quantity_returned,
        COALESCE(sr.sr_return_amt, 0)                                    AS return_amount,
        COALESCE(ss.ss_item_sk, sr.sr_item_sk)                           AS item_sk,
        COALESCE(ss.ss_customer_sk, sr.sr_customer_sk)                   AS customer_sk,
        COALESCE(ss.ss_store_sk, sr.sr_store_sk)                         AS store_sk,
        COALESCE(ss.ss_sold_time_sk, sr.sr_return_time_sk)               AS time_sk
    FROM sampled_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
)
SELECT
    CONCAT(c.c_first_name, ' ', c.c_last_name)                                 AS customer_name,
    i.i_item_id,
    i.i_item_desc,
    REGEXP_EXTRACT(i.i_item_desc, '(\\w+)$')                                   AS last_word_desc,
    CASE WHEN REGEXP_LIKE(i.i_item_desc, '(?i)shirt') THEN 'Shirt' ELSE 'Other' END AS item_category_flag,
    s.s_store_name,
    COUNT(DISTINCT joined.ticket_number)                                         AS sales_transactions,
    SUM(joined.net_paid)                                                          AS total_sales_net_paid,
    SUM(joined.return_amount)                                                     AS total_return_amount,
    SUM(joined.net_profit) - SUM(joined.return_amount)                           AS net_profit_after_returns
FROM joined
LEFT JOIN customer c ON joined.customer_sk = c.c_customer_sk
LEFT JOIN item i ON joined.item_sk = i.i_item_sk
LEFT JOIN store s ON joined.store_sk = s.s_store_sk
WHERE i.i_item_desc LIKE '%size%'
GROUP BY
    CONCAT(c.c_first_name, ' ', c.c_last_name),
    i.i_item_id,
    i.i_item_desc,
    REGEXP_EXTRACT(i.i_item_desc, '(\\w+)$'),
    CASE WHEN REGEXP_LIKE(i.i_item_desc, '(?i)shirt') THEN 'Shirt' ELSE 'Other' END,
    s.s_store_name
ORDER BY total_sales_net_paid DESC
LIMIT 100
