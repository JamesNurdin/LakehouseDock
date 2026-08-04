WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_warehouse_sk,
        cs.cs_quantity,
        wr.wr_return_amt,
        d.d_year,
        w.w_warehouse_name,
        w.w_state,
        r.r_reason_desc,
        ws.web_manager
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
           AND wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
           AND ws.web_close_date_sk = d.d_date_sk
    WHERE cs.cs_ship_date_sk = d.d_date_sk
      AND d.d_year = 2001
      AND w.w_state = 'CA'
      AND ws.web_manager = 'Ronald Shaffer'
      AND r.r_reason_desc LIKE '%fault%'
),

agg AS (
    SELECT
        w_warehouse_name,
        d_year,
        SUM(cs_net_profit)      AS total_profit,
        SUM(wr_return_amt)      AS total_return_amt,
        COUNT(*)                AS sales_cnt
    FROM base
    GROUP BY w_warehouse_name, d_year
),

filtered1 AS (
    SELECT w_warehouse_name, d_year, total_profit
    FROM agg
    WHERE total_profit > 50000
),

filtered2 AS (
    SELECT w_warehouse_name, d_year, total_profit
    FROM agg
    WHERE total_return_amt > 20000
),

union_set AS (
    SELECT w_warehouse_name, d_year, total_profit FROM filtered1
    UNION
    SELECT w_warehouse_name, d_year, total_profit FROM filtered2
),

rownum_set AS (
    SELECT
        w_warehouse_name,
        d_year,
        total_profit,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rn
    FROM union_set
),

intersect_keys AS (
    SELECT w_warehouse_name FROM filtered1
    INTERSECT
    SELECT w_warehouse_name FROM filtered2
)

SELECT
    rs.w_warehouse_name,
    rs.d_year,
    rs.total_profit,
    rs.rn
FROM rownum_set rs
JOIN intersect_keys ik
    ON rs.w_warehouse_name = ik.w_warehouse_name
ORDER BY rs.total_profit DESC
LIMIT 100
