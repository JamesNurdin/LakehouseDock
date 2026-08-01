WITH unified_sales AS (
    -- Catalog sales aggregated by customer and shift
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        t.t_shift,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_coupon_amt > 100
      AND t.t_am_pm = 'PM'
    GROUP BY c.c_customer_sk, c.c_customer_id, t.t_shift

    UNION ALL

    -- Web sales aggregated by customer and shift
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        t.t_shift,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax,
        'web' AS channel
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_wholesale_cost > 30
      AND t.t_am_pm = 'PM'
    GROUP BY c.c_customer_sk, c.c_customer_id, t.t_shift
)
SELECT DISTINCT
    us.c_customer_id,
    us.t_shift,
    us.channel,
    us.total_net_paid_inc_ship_tax
FROM unified_sales us
WHERE EXISTS (
    SELECT 1
    FROM unified_sales us2
    WHERE us2.c_customer_sk = us.c_customer_sk
      AND us2.channel <> us.channel
)
ORDER BY us.total_net_paid_inc_ship_tax DESC
LIMIT 100
