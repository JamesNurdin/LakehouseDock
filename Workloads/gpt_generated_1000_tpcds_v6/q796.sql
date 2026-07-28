WITH daily_sales AS (
    SELECT
        d_sold.d_date AS sold_date,
        sm.sm_carrier,
        sm.sm_contract,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year = 2000                     -- predicate 1
      AND sm.sm_carrier IN ('MSC', 'TBS')           -- predicate 2
      AND ws.ws_wholesale_cost > 30                -- predicate 3
      AND ws.ws_quantity >= 2                      -- predicate 4
      AND (d_ship.d_month_seq IS NULL               -- handling left join nulls
           OR d_ship.d_month_seq = d_sold.d_month_seq)
    GROUP BY d_sold.d_date, sm.sm_carrier, sm.sm_contract
)
SELECT
    carrier,
    contract,
    AVG(total_net_paid) AS avg_net_paid,
    SUM(order_cnt) AS total_orders,
    MAX(total_discount) AS max_discount
FROM (
    SELECT
        sm_carrier AS carrier,
        sm_contract AS contract,
        total_net_paid,
        total_discount,
        order_cnt
    FROM daily_sales ds
    WHERE ds.total_net_paid > (
        SELECT AVG(total_net_paid) FROM daily_sales
    )
) filtered
GROUP BY carrier, contract
HAVING COUNT(*) >= 3
ORDER BY avg_net_paid DESC
LIMIT 100
