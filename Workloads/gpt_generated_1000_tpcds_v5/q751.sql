/* goal: Rank warehouses by total net paid (catalog and web sales) for each year, showing yearly subtotals and grand total using ROLLUP, with filters on year, warehouse size, ship mode, call‑center staff and web‑site state. */
WITH joined AS (
    SELECT
        w.w_warehouse_name,
        d_cs_sold.d_year AS year,
        cs.cs_net_paid,
        ws.ws_net_paid,
        wr.wr_net_loss,
        sm.sm_type,
        cc.cc_employees,
        ws_site.web_state
    FROM catalog_sales cs
    JOIN date_dim d_cs_sold      ON cs.cs_sold_date_sk   = d_cs_sold.d_date_sk
    JOIN date_dim d_cs_ship      ON cs.cs_ship_date_sk   = d_cs_ship.d_date_sk
    JOIN call_center cc         ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm           ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w            ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN web_sales ws           ON cs.cs_order_number   = ws.ws_order_number   -- indirect link via shared dimensions (ship_mode & warehouse)
    JOIN date_dim d_ws_sold      ON ws.ws_sold_date_sk   = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship      ON ws.ws_ship_date_sk   = d_ws_ship.d_date_sk
    JOIN ship_mode sm_ws        ON ws.ws_ship_mode_sk   = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws         ON ws.ws_warehouse_sk   = w_ws.w_warehouse_sk
    JOIN web_site ws_site       ON ws.ws_web_site_sk    = ws_site.web_site_sk
    JOIN date_dim d_ws_open     ON ws_site.web_open_date_sk  = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close    ON ws_site.web_close_date_sk = d_ws_close.d_date_sk
    JOIN web_returns wr        ON ws.ws_item_sk       = wr.wr_item_sk
                                 AND ws.ws_order_number = wr.wr_order_number
    JOIN date_dim d_wr_returned ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
    WHERE d_cs_sold.d_year = 2001                                   -- filter 1: specific year
      AND w.w_warehouse_sq_ft > 500000                               -- filter 2: large warehouses
      AND sm.sm_type = 'AIR'                                         -- filter 3: air shipping only
      AND cc.cc_employees >= 200                                    -- filter 4: sizable call centre staff
      AND ws_site.web_state = 'CA'                                   -- filter 5: California web sites
),
agg AS (
    SELECT
        w_warehouse_name,
        year,
        SUM(cs_net_paid)   AS total_cs_net_paid,
        SUM(ws_net_paid)   AS total_ws_net_paid,
        SUM(wr_net_loss)   AS total_wr_net_loss
    FROM joined
    GROUP BY ROLLUP (w_warehouse_name, year)
)
SELECT
    w_warehouse_name,
    year,
    total_cs_net_paid,
    total_ws_net_paid,
    total_wr_net_loss,
    ROW_NUMBER() OVER (
        PARTITION BY w_warehouse_name
        ORDER BY COALESCE(total_cs_net_paid, 0) + COALESCE(total_ws_net_paid, 0) DESC
    ) AS rank_per_warehouse
FROM agg
ORDER BY w_warehouse_name ASC NULLS LAST,
         rank_per_warehouse ASC,
         year ASC NULLS LAST
LIMIT 100
