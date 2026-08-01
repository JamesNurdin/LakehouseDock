WITH
    sales_filtered AS (
        SELECT
            cs.cs_order_number AS order_num,
            cs.cs_ext_sales_price AS amount,
            ca.ca_state
        FROM catalog_sales cs
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        WHERE cs.cs_ext_sales_price > 5000
    ),
    returns_filtered AS (
        SELECT
            wr.wr_order_number AS order_num,
            wr.wr_return_amt AS amount,
            ca.ca_state
        FROM web_returns wr
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        WHERE wr.wr_return_amt > 1000
    ),
    union_all_events AS (
        SELECT order_num, amount, 'sale'   AS event_type, ca_state FROM sales_filtered
        UNION ALL
        SELECT order_num, amount, 'return' AS event_type, ca_state FROM returns_filtered
    ),
    exclusive_sales AS (
        SELECT order_num FROM sales_filtered
        EXCEPT
        SELECT order_num FROM returns_filtered
    ),
    full_sales_returns AS (
        SELECT
            cs_sub.addr_sk,
            cs_sub.cs_order_number,
            cs_sub.cs_ext_sales_price,
            cs_sub.cs_net_profit,
            wr_sub.wr_order_number,
            wr_sub.wr_return_amt,
            wr_sub.wr_net_loss,
            CASE
                WHEN cs_sub.cs_net_profit IS NOT NULL THEN cs_sub.cs_net_profit
                ELSE -wr_sub.wr_net_loss
            END AS profit_or_loss
        FROM (
            SELECT
                cs.cs_bill_addr_sk AS addr_sk,
                cs.cs_order_number,
                cs.cs_ext_sales_price,
                cs.cs_net_profit
            FROM catalog_sales cs
            JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
            WHERE cs.cs_ext_sales_price > 4000
        ) cs_sub
        FULL OUTER JOIN (
            SELECT
                wr.wr_refunded_addr_sk AS addr_sk,
                wr.wr_order_number,
                wr.wr_return_amt,
                wr.wr_net_loss
            FROM web_returns wr
            JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
            WHERE wr.wr_return_amt > 500
        ) wr_sub
        ON cs_sub.addr_sk = wr_sub.addr_sk
    )
SELECT
    f.addr_sk,
    f.cs_order_number,
    f.wr_order_number,
    f.profit_or_loss,
    CASE
        WHEN f.cs_order_number IS NOT NULL THEN 'sale'
        WHEN f.wr_order_number IS NOT NULL THEN 'return'
        ELSE 'unknown'
    END AS record_type,
    (
        SELECT COUNT(*)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_addr_sk = f.addr_sk
    ) AS sales_count_for_addr,
    CASE
        WHEN f.addr_sk IN (SELECT order_num FROM exclusive_sales) THEN 'exclusive_sale'
        ELSE 'other'
    END AS exclusivity_flag
FROM full_sales_returns f
WHERE f.addr_sk IS NOT NULL
ORDER BY f.profit_or_loss DESC
LIMIT 100
