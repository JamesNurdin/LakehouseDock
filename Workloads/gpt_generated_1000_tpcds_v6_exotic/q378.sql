WITH sales AS (
    SELECT
        CAST(ws.ws_bill_addr_sk AS VARCHAR) AS identifier,
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_ext_sales_price) AS amount
    FROM web_sales ws
    WHERE CAST(ws.ws_bill_addr_sk AS VARCHAR) LIKE '%7%'
    GROUP BY ws.ws_bill_addr_sk, ws.ws_item_sk
),
returns AS (
    SELECT
        CAST(wr.wr_refunded_hdemo_sk AS VARCHAR) AS identifier,
        wr.wr_item_sk AS item_sk,
        -SUM(wr.wr_return_amt) AS amount
    FROM web_returns wr
    WHERE regexp_like(CAST(wr.wr_refunded_hdemo_sk AS VARCHAR), '^1[0-9]{3}$')
    GROUP BY wr.wr_refunded_hdemo_sk, wr.wr_item_sk
),
combined AS (
    SELECT identifier, item_sk, amount FROM sales
    UNION ALL
    SELECT identifier, item_sk, amount FROM returns
)
SELECT
    identifier,
    item_sk,
    SUM(amount) AS total_amount,
    GROUPING(identifier) AS grp_identifier,
    GROUPING(item_sk) AS grp_item
FROM combined
GROUP BY GROUPING SETS (
    (identifier, item_sk),
    (identifier),
    (item_sk),
    ()
)
ORDER BY identifier, item_sk
LIMIT 100
