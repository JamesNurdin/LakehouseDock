WITH
    cs_filtered AS (
        SELECT
            cs.cs_sold_date_sk,
            SUM(cs.cs_net_profit) AS profit_cs,
            COUNT(*) AS cnt_cs
        FROM catalog_sales cs
        LEFT JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        WHERE cs.cs_quantity >= 2
          AND cs.cs_net_paid_inc_ship > 500
          AND cs.cs_wholesale_cost > 10
          AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
        GROUP BY cs.cs_sold_date_sk
    ),
    ws_filtered AS (
        SELECT
            ws.ws_sold_date_sk,
            SUM(ws.ws_net_profit) AS profit_ws,
            COUNT(*) AS cnt_ws
        FROM web_sales ws
        LEFT JOIN household_demographics hd
            ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        WHERE ws.ws_quantity >= 2
          AND ws.ws_net_paid_inc_ship > 500
          AND ws.ws_wholesale_cost > 10
          AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
        GROUP BY ws.ws_sold_date_sk
    ),
    union_agg AS (
        SELECT cs_sold_date_sk AS date_sk, profit_cs AS profit
        FROM cs_filtered
        UNION
        SELECT ws_sold_date_sk, profit_ws
        FROM ws_filtered
    ),
    intersect_dates AS (
        SELECT inv.inv_date_sk
        FROM inventory inv
        INNER JOIN date_dim d
            ON inv.inv_date_sk = d.d_date_sk
        WHERE inv.inv_quantity_on_hand > 100
          AND d.d_year = 2001
        INTERSECT
        SELECT date_sk FROM union_agg
    ),
    full_joined AS (
        SELECT
            d.d_date_sk,
            d.d_date,
            d.d_year,
            inv.inv_quantity_on_hand
        FROM date_dim d
        FULL OUTER JOIN inventory inv
            ON d.d_date_sk = inv.inv_date_sk
        WHERE d.d_year = 2001
    ),
    final AS (
        SELECT
            f.d_date,
            f.d_year,
            f.inv_quantity_on_hand,
            u.profit,
            RANK() OVER (PARTITION BY f.d_year ORDER BY u.profit DESC) AS profit_rank
        FROM full_joined f
        JOIN intersect_dates i
            ON f.d_date_sk = i.inv_date_sk
        JOIN union_agg u
            ON u.date_sk = i.inv_date_sk
        WHERE f.inv_quantity_on_hand IS NOT NULL
          AND u.profit > (SELECT AVG(profit) FROM union_agg)
    )
SELECT
    d_date,
    d_year,
    inv_quantity_on_hand,
    profit,
    profit_rank,
    CASE WHEN profit_rank = 1 THEN 'Top Profit Day' ELSE 'Other' END AS profit_category
FROM final
ORDER BY d_year, profit_rank
LIMIT 100
