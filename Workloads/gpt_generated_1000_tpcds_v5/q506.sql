WITH time_info AS (
    SELECT t_time_sk,
           t_sub_shift
    FROM   time_dim
    WHERE  t_sub_shift IN ('morning', 'afternoon', 'evening')
)
SELECT
    source,
    sub_shift,
    total_qty,
    total_amount,
    distinct_counter
FROM (
    SELECT
        'store_return' AS source,
        ti.t_sub_shift AS sub_shift,
        SUM(sr.sr_return_quantity) AS total_qty,
        SUM(sr.sr_return_amt) AS total_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_counter
    FROM   store_returns sr
    JOIN   time_info ti ON sr.sr_return_time_sk = ti.t_time_sk
    WHERE  sr.sr_return_quantity > 10
    GROUP BY ti.t_sub_shift
    HAVING SUM(sr.sr_return_amt) > 1000

    UNION ALL

    SELECT
        'web_sale' AS source,
        ti.t_sub_shift AS sub_shift,
        SUM(ws.ws_quantity) AS total_qty,
        SUM(ws.ws_ext_sales_price) AS total_amount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_counter
    FROM   web_sales ws
    JOIN   time_info ti ON ws.ws_sold_time_sk = ti.t_time_sk
    WHERE  ws.ws_ext_sales_price > 200
    GROUP BY ti.t_sub_shift
    HAVING SUM(ws.ws_quantity) >= 20
) AS combined
ORDER BY source, total_qty DESC
LIMIT 100
