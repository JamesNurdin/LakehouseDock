WITH sales_agg AS (
    SELECT
        s.s_store_name AS store_name,
        td.t_hour AS hour,
        'sale' AS transaction_type,
        SUM(ss.ss_ext_sales_price) AS amount,
        SUM(ss.ss_net_profit) AS net,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_sub_shift = 'morning'
      AND s.s_state = 'CA'
    GROUP BY s.s_store_name, td.t_hour
),
returns_agg AS (
    SELECT
        s.s_store_name AS store_name,
        td.t_hour AS hour,
        'return' AS transaction_type,
        SUM(sr.sr_return_amt) AS amount,
        SUM(sr.sr_net_loss) AS net,
        CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_sub_shift = 'morning'
      AND s.s_state = 'CA'
    GROUP BY s.s_store_name, td.t_hour
),
combined AS (
    SELECT DISTINCT store_name, hour, transaction_type, amount, net, profit_flag
    FROM sales_agg
    UNION
    SELECT DISTINCT store_name, hour, transaction_type, amount, net, profit_flag
    FROM returns_agg
),
ranked AS (
    SELECT
        store_name,
        hour,
        transaction_type,
        amount,
        net,
        profit_flag,
        ROW_NUMBER() OVER (PARTITION BY store_name ORDER BY amount DESC) AS rn
    FROM combined
)
SELECT
    store_name,
    hour,
    transaction_type,
    amount,
    net,
    profit_flag
FROM ranked
WHERE rn <= 5
ORDER BY store_name, rn
LIMIT 100
