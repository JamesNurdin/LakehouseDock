WITH sales_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    GROUP BY ws.ws_item_sk, ws.ws_ship_mode_sk
)
SELECT
    i.i_category,
    i.i_product_name,
    sm.sm_code,
    sales.total_profit,
    sales.total_quantity,
    sales.order_cnt,
    regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word_desc,
    (
        SELECT MAX(wr.wr_return_amt)
        FROM web_returns wr
        WHERE wr.wr_item_sk = i.i_item_sk
    ) AS max_return_amount
FROM sales_agg sales
JOIN item i
    ON sales.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON sales.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    regexp_like(i.i_item_desc, '^.*[A-Z]{3}.*$')
    AND sm.sm_code LIKE 'A%'
    AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = i.i_item_sk
          AND wr.wr_account_credit > 0
          AND wr.wr_return_tax > 10
    )
ORDER BY sales.total_profit DESC
LIMIT 100
