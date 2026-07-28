WITH returns_agg AS (
    SELECT
        wr_order_number,
        wr_item_sk,
        SUM(wr_return_amt)          AS total_return_amt,
        SUM(wr_fee)                 AS total_fee,
        SUM(wr_net_loss)            AS total_net_loss
    FROM web_returns
    WHERE
        wr_return_amt > 0
        AND wr_fee >= 10
        AND wr_return_ship_cost < 100
        AND wr_account_credit > 0
        AND wr_return_quantity >= 1
        AND wr_returned_date_sk IS NOT NULL
    GROUP BY
        wr_order_number,
        wr_item_sk
)
SELECT
    d_sold.d_year,
    d_sold.d_week_seq,
    sm.sm_ship_mode_id,
    sm.sm_contract,
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ra.total_return_amt,
    ws.ws_net_profit - COALESCE(ra.total_return_amt, 0)                     AS adjusted_profit,
    CASE
        WHEN ws.ws_net_profit - COALESCE(ra.total_return_amt, 0) > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END                                                                     AS profit_indicator,
    RANK() OVER (PARTITION BY d_sold.d_year ORDER BY (ws.ws_net_profit - COALESCE(ra.total_return_amt, 0)) DESC) AS profit_rank_year
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN returns_agg ra
    ON ws.ws_order_number = ra.wr_order_number
   AND ws.ws_item_sk = ra.wr_item_sk
WHERE
    d_sold.d_year = 2001                                 -- predicate 1
    AND d_sold.d_week_seq BETWEEN 10 AND 20               -- predicate 2
    AND d_ship.d_month_seq = 3                            -- predicate 3
    AND sm.sm_contract = 'fop0bcSd91J26IVpR'              -- predicate 4
    AND ws.ws_quantity > 1                                -- predicate 5
    AND ws.ws_ext_sales_price > 100                       -- predicate 6
    AND ws.ws_net_profit IS NOT NULL                     -- predicate 7
ORDER BY
    profit_rank_year,
    d_sold.d_week_seq
LIMIT 100
