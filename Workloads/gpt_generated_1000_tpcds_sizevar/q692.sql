WITH returns AS (
    SELECT
        'return' AS src_type,
        r.r_reason_desc AS reason_desc,
        i.i_brand AS item_brand,
        SUM(sr.sr_return_amt_inc_tax) AS total_amount
    FROM store_returns sr TABLESAMPLE BERNOULLI (10)
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_customer_sk IN (
        SELECT c.c_customer_sk
        FROM customer c
        WHERE c.c_preferred_cust_flag = 'Y'
    )
      AND i.i_category = 'Electronics'
    GROUP BY r.r_reason_desc, i.i_brand
),
sales AS (
    SELECT
        'sale' AS src_type,
        CAST(NULL AS varchar) AS reason_desc,
        i.i_brand AS item_brand,
        SUM(ws.ws_net_paid_inc_tax) AS total_amount
    FROM web_sales ws TABLESAMPLE BERNOULLI (10)
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_item_sk IN (
        SELECT sr2.sr_item_sk
        FROM store_returns sr2
        WHERE sr2.sr_return_quantity > 5
    )
      AND ws.ws_net_paid_inc_tax > 500
    GROUP BY i.i_brand
)
SELECT src_type,
       reason_desc,
       item_brand,
       total_amount
FROM (
    SELECT * FROM returns
    UNION
    SELECT * FROM sales
) AS combined
ORDER BY total_amount DESC
OFFSET 10 LIMIT 100
