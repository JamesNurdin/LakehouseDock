WITH
    sampled_sales AS (
        SELECT *
        FROM store_sales TABLESAMPLE BERNOULLI (10)
    ),
    store_sales_joined AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_store_sk,
            ss.ss_quantity,
            ss.ss_ext_sales_price,
            ss.ss_net_profit,
            s.s_store_id,
            s.s_city,
            s.s_state,
            s.s_zip,
            t.t_am_pm,
            t.t_second,
            wr.wr_return_amt
        FROM sampled_sales ss
        FULL OUTER JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN time_dim t
            ON ss.ss_sold_time_sk = t.t_time_sk
        LEFT JOIN web_returns wr
            ON t.t_time_sk = wr.wr_returned_time_sk
        WHERE
            ss.ss_quantity > 10
            AND ss.ss_ext_sales_price > 200
            AND s.s_state = 'CA'
            AND t.t_am_pm = 'PM'
            AND t.t_second BETWEEN 1 AND 20
            AND ss.ss_net_profit > 0
            AND (wr.wr_return_amt IS NULL OR wr.wr_return_amt < 1000)
    ),
    missing_store_keys AS (
        SELECT ss_store_sk FROM store_sales
        EXCEPT
        SELECT s_store_sk FROM store
    ),
    ranked_sales AS (
        SELECT
            ssj.ss_sold_date_sk,
            ssj.s_store_id,
            ssj.s_city,
            ssj.s_state,
            ssj.ss_quantity,
            ssj.ss_ext_sales_price,
            ssj.ss_net_profit,
            ssj.wr_return_amt,
            ssj.ss_store_sk,
            ROW_NUMBER() OVER (
                PARTITION BY ssj.s_store_id
                ORDER BY ssj.ss_ext_sales_price DESC
            ) AS rn,
            RANK() OVER (
                PARTITION BY ssj.s_state
                ORDER BY ssj.ss_net_profit DESC
            ) AS profit_rank,
            SUM(ssj.ss_ext_sales_price) OVER (
                PARTITION BY ssj.s_store_id
                ORDER BY ssj.ss_sold_date_sk
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ) AS moving_sum_3,
            CASE
                WHEN ssj.ss_store_sk IN (SELECT ss_store_sk FROM missing_store_keys) THEN 'Missing'
                ELSE 'Present'
            END AS store_key_status
        FROM store_sales_joined ssj
        WHERE ssj.s_store_id IS NOT NULL
    )
SELECT
    rs.ss_sold_date_sk,
    rs.s_store_id,
    rs.s_city,
    rs.ss_quantity,
    rs.ss_ext_sales_price,
    rs.ss_net_profit,
    rs.wr_return_amt,
    rs.moving_sum_3,
    rs.rn,
    rs.profit_rank,
    rs.store_key_status
FROM ranked_sales rs
WHERE rs.rn <= 5
ORDER BY rs.profit_rank, rs.ss_ext_sales_price DESC
LIMIT 100
