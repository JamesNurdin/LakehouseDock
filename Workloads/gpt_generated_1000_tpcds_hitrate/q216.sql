WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        ws.ws_net_paid_inc_ship,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_dow,
        d.d_fy_quarter_seq
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
      AND ws.ws_net_paid_inc_ship > 500
      AND ws.ws_quantity >= 1
),
small_dim AS (
    SELECT DISTINCT d_dow
    FROM date_dim
    WHERE d_year = 2001
    LIMIT 5
),
 buckets AS (
    SELECT 1 AS bucket UNION ALL SELECT 2 UNION ALL SELECT 3
),
ranked_sales AS (
    SELECT
        ws_order_number,
        d_date,
        d_year,
        d_month_seq,
        d_dow,
        ws_quantity,
        ws_net_paid_inc_ship,
        RANK() OVER (PARTITION BY d_year ORDER BY ws_net_paid_inc_ship DESC) AS yearly_rank,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY ws_net_paid_inc_ship DESC) AS rn
    FROM filtered_sales
)
SELECT
    rs.ws_order_number,
    rs.d_date,
    rs.d_year,
    rs.d_month_seq,
    rs.d_dow,
    rs.ws_quantity,
    rs.ws_net_paid_inc_ship,
    rs.yearly_rank,
    -- correlated scalar subquery: total quantity for the same order
    (SELECT SUM(ws2.ws_quantity)
     FROM web_sales ws2
     WHERE ws2.ws_order_number = rs.ws_order_number) AS total_qty_per_order,
    -- cross‑joined dimension values
    sd.d_dow AS cross_dow,
    b.bucket
FROM ranked_sales rs
CROSS JOIN small_dim sd
CROSS JOIN buckets b
WHERE rs.yearly_rank <= 10
ORDER BY rs.d_year, rs.yearly_rank
LIMIT 100
