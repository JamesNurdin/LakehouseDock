WITH sales_filtered AS (
    SELECT
        ss_ticket_number,
        ss_item_sk,
        ss_store_sk,
        ss_customer_sk,
        ss_ext_sales_price,
        ss_net_profit
    FROM store_sales
    WHERE ss_ext_sales_price > (
            SELECT MAX(ss_ext_sales_price)
            FROM store_sales
            WHERE ss_store_sk = 1
        )
      AND regexp_like(CAST(ss_customer_sk AS VARCHAR), '^9[0-9]{6}$')
      AND CAST(ss_customer_sk AS VARCHAR) LIKE '9%'
),
agg AS (
    SELECT
        s.ss_store_sk,
        s.ss_item_sk,
        s.ss_customer_sk,
        COUNT(*) AS sales_cnt,
        SUM(s.ss_ext_sales_price) AS total_sales,
        SUM(CASE WHEN r.sr_return_quantity > 0 THEN r.sr_return_amt ELSE 0 END) AS total_return_amt,
        SUM(s.ss_net_profit) - SUM(CASE WHEN r.sr_return_quantity > 0 THEN r.sr_return_amt ELSE 0 END) AS net_profit_adjusted,
        CONCAT('Store_', CAST(s.ss_store_sk AS VARCHAR), '_Item_', CAST(s.ss_item_sk AS VARCHAR)) AS store_item_key,
        regexp_extract(CAST(s.ss_customer_sk AS VARCHAR), '(9[0-9]{2})([0-9]{4})', 1) AS cust_prefix
    FROM sales_filtered s
    LEFT JOIN store_returns r
        ON s.ss_item_sk = r.sr_item_sk
        AND s.ss_ticket_number = r.sr_ticket_number
    GROUP BY
        s.ss_store_sk,
        s.ss_item_sk,
        s.ss_customer_sk
)
SELECT
    a.ss_store_sk,
    a.ss_item_sk,
    a.sales_cnt,
    a.total_sales,
    a.total_return_amt,
    a.net_profit_adjusted,
    a.store_item_key,
    a.cust_prefix,
    ROW_NUMBER() OVER (PARTITION BY a.ss_store_sk ORDER BY a.total_sales DESC) AS profit_rank
FROM agg a
ORDER BY a.net_profit_adjusted DESC
LIMIT 100
