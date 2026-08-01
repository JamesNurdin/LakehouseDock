WITH sales_returns AS (
    SELECT
        i.i_item_id AS i_item_id,
        i.i_category AS i_category,
        d_sales.d_year AS d_year,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        i.i_category = 'Electronics'
        AND c.c_birth_country = 'MEXICO'
        AND d_sales.d_year = 2002
        AND sr.sr_return_quantity > 0
        AND r.r_reason_desc = 'Damaged'
        AND EXISTS (
            SELECT 1
            FROM web_site ws
            WHERE ws.web_open_date_sk = d_sales.d_date_sk
                AND ws.web_country = 'USA'
                AND ws.web_name LIKE '%Shop%'
        )
    GROUP BY i.i_item_id, i.i_category, d_sales.d_year
    HAVING SUM(ss.ss_net_profit) > 1000
)
SELECT
    sr.i_item_id,
    sr.i_category,
    sr.d_year,
    sr.total_net_profit,
    sr.total_return_amt,
    sr.return_count,
    ROW_NUMBER() OVER (PARTITION BY sr.i_category ORDER BY sr.total_net_profit DESC) AS rn_category
FROM sales_returns sr
ORDER BY sr.total_net_profit DESC
LIMIT 100
