WITH
    ws_agg AS (
        SELECT
            cd.cd_gender               AS gender,
            d.d_year                   AS year,
            SUM(ws.ws_net_profit)      AS total_net_profit,
            COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            CASE WHEN SUM(ws.ws_quantity) = 0 THEN 0
                 ELSE SUM(ws.ws_ext_sales_price) / SUM(ws.ws_quantity)
            END                         AS avg_price_per_unit
        FROM
            web_sales ws
            INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
            INNER JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        WHERE
            d.d_year BETWEEN 1999 AND 2001               -- predicate 1
            AND cd.cd_gender = 'M'                       -- predicate 2
            AND ws.ws_ext_list_price > 1000              -- predicate 3
            AND ws.ws_quantity >= 1                     -- predicate 4
            AND ws.ws_net_profit > 0                    -- predicate 5
            AND ws.ws_ship_mode_sk IS NOT NULL          -- predicate 6
        GROUP BY
            cd.cd_gender,
            d.d_year
    ),
    sr_agg AS (
        SELECT
            cd.cd_gender               AS gender,
            d.d_year                   AS year,
            SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
            COUNT(*)                   AS return_cnt
        FROM
            store_returns sr
            INNER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
            INNER JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE
            d.d_year BETWEEN 1999 AND 2001               -- predicate 7
            AND cd.cd_gender = 'M'                       -- predicate 8
            AND sr.sr_return_amt_inc_tax > 0             -- predicate 9
            AND sr.sr_return_quantity > 0               -- predicate 10
            AND sr.sr_fee >= 0                           -- predicate 11
            AND sr.sr_net_loss > 0                       -- predicate 12
        GROUP BY
            cd.cd_gender,
            d.d_year
    )
SELECT
    w.gender,
    w.year,
    w.total_net_profit,
    w.total_sales,
    COALESCE(s.total_return_amt, 0)               AS total_return_amt,
    w.distinct_orders,
    COALESCE(s.return_cnt, 0)                     AS return_cnt,
    CASE WHEN s.total_return_amt IS NULL THEN 'No Returns' ELSE 'Has Returns' END AS return_status,
    (w.total_net_profit - COALESCE(s.total_return_amt, 0)) AS net_profit_minus_returns,
    w.total_net_profit / NULLIF(w.distinct_orders, 0)       AS profit_per_order
FROM
    ws_agg w
    LEFT OUTER JOIN sr_agg s
        ON w.gender = s.gender AND w.year = s.year
ORDER BY
    w.year DESC,
    w.total_net_profit DESC
LIMIT 100
