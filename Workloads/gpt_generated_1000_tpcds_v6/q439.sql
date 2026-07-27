WITH inventory_avg AS (
    SELECT inv.inv_warehouse_sk,
           AVG(inv.inv_quantity_on_hand) AS avg_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY inv.inv_warehouse_sk
)
SELECT year,
       store_name,
       metric_amount,
       metric_count,
       flag,
       avg_qty,
       max_warehouse_sq_ft
FROM (
    SELECT
        d.d_year AS year,
        s.s_store_name AS store_name,
        SUM(ws.ws_net_profit) AS metric_amount,
        COUNT(*) AS metric_count,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS flag,
        ia.avg_qty,
        (SELECT MAX(w_warehouse_sq_ft) FROM warehouse) AS max_warehouse_sq_ft
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory_avg ia ON ws.ws_warehouse_sk = ia.inv_warehouse_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM inventory inv2
          WHERE inv2.inv_warehouse_sk = ws.ws_warehouse_sk
            AND inv2.inv_quantity_on_hand > 0
      )
    GROUP BY d.d_year, s.s_store_name, ia.avg_qty

    UNION ALL

    SELECT
        d.d_year AS year,
        s.s_store_name AS store_name,
        SUM(wr.wr_net_loss) AS metric_amount,
        COUNT(*) AS metric_count,
        CASE WHEN SUM(wr.wr_net_loss) > 0 THEN 'LOSS' ELSE 'NO_LOSS' END AS flag,
        CAST(NULL AS double) AS avg_qty,
        (SELECT MAX(w_warehouse_sq_ft) FROM warehouse) AS max_warehouse_sq_ft
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
    GROUP BY d.d_year, s.s_store_name
) AS combined
LIMIT 100
