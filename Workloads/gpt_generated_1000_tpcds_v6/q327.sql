WITH high_return_items AS (
    SELECT i.i_category AS i_category,
           SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
    GROUP BY i.i_category
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT combined.category,
       combined.metric_type,
       combined.amount
FROM (
    -- Store sales aggregation
    SELECT i.i_category AS category,
           'sales'   AS metric_type,
           SUM(ss.ss_ext_sales_price) AS amount
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_market_desc LIKE '%Local%'
    GROUP BY i.i_category
    HAVING SUM(ss.ss_ext_sales_price) > 5000

    UNION ALL

    -- Web returns aggregation
    SELECT i.i_category AS category,
           'returns'   AS metric_type,
           SUM(wr.wr_return_amt) AS amount
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE EXISTS (
        SELECT 1
        FROM customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        WHERE c.c_customer_sk = wr.wr_refunded_customer_sk
          AND cd.cd_gender = 'F'
    )
    GROUP BY i.i_category
    HAVING SUM(wr.wr_return_amt) > 2000
) AS combined
WHERE combined.category IN (SELECT i_category FROM high_return_items)
ORDER BY combined.amount DESC
LIMIT 100
