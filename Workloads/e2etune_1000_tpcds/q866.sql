WITH cs_agg AS (
    SELECT
        cs_item_sk AS item_sk,
        date_trunc('month', date_add('day', cs_sold_date_sk, date '1970-01-01')) AS month_start,
        SUM(cs_net_paid_inc_tax) AS cs_total_paid,
        SUM(cs_net_profit) AS cs_total_profit,
        SUM(cs_quantity) AS cs_total_qty,
        AVG(cs_ext_discount_amt) AS cs_avg_discount,
        COUNT(*) AS cs_orders
    FROM catalog_sales
    WHERE cs_promo_sk IN (843, 587)
      AND cs_call_center_sk = 8
    GROUP BY cs_item_sk, date_trunc('month', date_add('day', cs_sold_date_sk, date '1970-01-01'))
),
ws_agg AS (
    SELECT
        ws_item_sk AS item_sk,
        date_trunc('month', date_add('day', ws_sold_date_sk, date '1970-01-01')) AS month_start,
        SUM(ws_net_paid_inc_tax) AS ws_total_paid,
        SUM(ws_net_profit) AS ws_total_profit,
        SUM(ws_quantity) AS ws_total_qty,
        AVG(ws_ext_discount_amt) AS ws_avg_discount,
        COUNT(*) AS ws_orders
    FROM web_sales
    WHERE ws_ship_mode_sk = 4
      AND ws_promo_sk IN (843, 587)
    GROUP BY ws_item_sk, date_trunc('month', date_add('day', ws_sold_date_sk, date '1970-01-01'))
)
SELECT *
FROM (
    SELECT
        COALESCE(cs.item_sk, ws.item_sk) AS item_sk,
        COALESCE(cs.month_start, ws.month_start) AS month_start,
        COALESCE(cs.cs_total_paid, 0) AS cs_total_paid,
        COALESCE(ws.ws_total_paid, 0) AS ws_total_paid,
        (COALESCE(cs.cs_total_profit, 0) + COALESCE(ws.ws_total_profit, 0)) AS total_profit,
        (COALESCE(cs.cs_total_qty, 0) + COALESCE(ws.ws_total_qty, 0)) AS total_qty,
        CASE
            WHEN (COALESCE(cs.cs_total_qty, 0) + COALESCE(ws.ws_total_qty, 0)) = 0 THEN 0
            ELSE ((COALESCE(cs.cs_avg_discount, 0) * COALESCE(cs.cs_total_qty, 0))
                + (COALESCE(ws.ws_avg_discount, 0) * COALESCE(ws.ws_total_qty, 0)))
                / (COALESCE(cs.cs_total_qty, 0) + COALESCE(ws.ws_total_qty, 0))
        END AS weighted_avg_discount,
        (COALESCE(cs.cs_orders, 0) + COALESCE(ws.ws_orders, 0)) AS total_orders,
        RANK() OVER (PARTITION BY COALESCE(cs.month_start, ws.month_start) ORDER BY (COALESCE(cs.cs_total_profit, 0) + COALESCE(ws.ws_total_profit, 0)) DESC) AS profit_rank
    FROM cs_agg cs
    FULL OUTER JOIN ws_agg ws
        ON cs.item_sk = ws.item_sk
       AND cs.month_start = ws.month_start
    WHERE (COALESCE(cs.cs_total_paid, 0) + COALESCE(ws.ws_total_paid, 0)) > 10000
) t
WHERE profit_rank <= 10
ORDER BY month_start, profit_rank
LIMIT 100
