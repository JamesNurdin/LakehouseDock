WITH
    /* Pre‑aggregate inventory per warehouse and date */
    inv_agg AS (
        SELECT
            inv_warehouse_sk,
            inv_date_sk,
            SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        GROUP BY inv_warehouse_sk, inv_date_sk
    ),
    /* Orders that appear both in catalog and web channels */
    common_orders AS (
        SELECT cs_order_number AS order_num FROM catalog_sales
        INTERSECT
        SELECT ws_order_number AS order_num FROM web_sales
    ),
    /* First branch – based on catalog sales */
    cat_branch AS (
        SELECT
            w.w_warehouse_name,
            d.d_year,
            w.w_warehouse_sk,
            ia.total_qty,
            SUM(cs.cs_net_profit)                           AS total_profit,
            CASE
                WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH'
                WHEN SUM(cs.cs_net_profit) >  50000 THEN 'MEDIUM'
                ELSE 'LOW'
            END                                            AS profit_tier
        FROM catalog_sales cs
        JOIN date_dim d                ON cs.cs_sold_date_sk   = d.d_date_sk
        JOIN warehouse w               ON cs.cs_warehouse_sk   = w.w_warehouse_sk
        JOIN inv_agg ia                ON ia.inv_warehouse_sk = w.w_warehouse_sk
                                      AND ia.inv_date_sk     = d.d_date_sk
        JOIN customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk   = hd.hd_demo_sk
        JOIN ship_mode sm              ON cs.cs_ship_mode_sk    = sm.sm_ship_mode_sk
        JOIN call_center cc            ON cs.cs_call_center_sk  = cc.cc_call_center_sk
        JOIN catalog_returns cr        ON cr.cr_order_number    = cs.cs_order_number
        JOIN reason r                  ON cr.cr_reason_sk       = r.r_reason_sk
        JOIN store_sales ss            ON ss.ss_customer_sk     = c.c_customer_sk
        JOIN web_sales ws              ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN web_site we               ON ws.ws_web_site_sk     = we.web_site_sk
        JOIN web_page wp               ON ws.ws_web_page_sk     = wp.wp_web_page_sk
        WHERE cs.cs_order_number IN (SELECT order_num FROM common_orders)
          AND d.d_year BETWEEN 1999 AND 2001
        GROUP BY w.w_warehouse_name, d.d_year, w.w_warehouse_sk, ia.total_qty
        HAVING SUM(cs.cs_net_profit) > 0
    ),
    /* Second branch – based on web sales */
    web_branch AS (
        SELECT
            w.w_warehouse_name,
            d.d_year,
            w.w_warehouse_sk,
            ia.total_qty,
            SUM(ws.ws_net_profit)                          AS total_profit,
            CASE
                WHEN SUM(ws.ws_net_profit) > 80000 THEN 'HIGH'
                WHEN SUM(ws.ws_net_profit) > 40000 THEN 'MEDIUM'
                ELSE 'LOW'
            END                                            AS profit_tier
        FROM web_sales ws
        JOIN date_dim d                ON ws.ws_sold_date_sk   = d.d_date_sk
        JOIN warehouse w               ON ws.ws_warehouse_sk   = w.w_warehouse_sk
        JOIN inv_agg ia                ON ia.inv_warehouse_sk = w.w_warehouse_sk
                                      AND ia.inv_date_sk     = d.d_date_sk
        JOIN customer c                ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk   = hd.hd_demo_sk
        JOIN ship_mode sm              ON ws.ws_ship_mode_sk    = sm.sm_ship_mode_sk
        JOIN web_site we               ON ws.ws_web_site_sk     = we.web_site_sk
        JOIN web_page wp               ON ws.ws_web_page_sk     = wp.wp_web_page_sk
        WHERE ws.ws_order_number IN (SELECT order_num FROM common_orders)
          AND d.d_year BETWEEN 1999 AND 2001
        GROUP BY w.w_warehouse_name, d.d_year, w.w_warehouse_sk, ia.total_qty
        HAVING SUM(ws.ws_net_profit) > 0
    ),
    /* Union of the two analytical branches */
    union_data AS (
        SELECT * FROM cat_branch
        UNION DISTINCT
        SELECT * FROM web_branch
    )
SELECT
    ud.w_warehouse_name,
    ud.d_year,
    ud.w_warehouse_sk,
    ud.total_qty,
    ud.total_profit,
    ud.profit_tier,
    /* Analytic window: prior year profit per warehouse */
    LAG(ud.total_profit) OVER (PARTITION BY ud.w_warehouse_name ORDER BY ud.d_year) AS prior_year_profit,
    ROW_NUMBER() OVER (PARTITION BY ud.w_warehouse_name ORDER BY ud.d_year DESC) AS rn,
    /* Scalar sub‑query: average paid amount for the warehouse */
    (SELECT AVG(cs2.cs_net_paid)
       FROM catalog_sales cs2
      WHERE cs2.cs_warehouse_sk = ud.w_warehouse_sk) AS avg_paid,
    cj.dummy
FROM union_data ud
CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2 AS dummy) cj
WHERE cj.dummy = 1
ORDER BY ud.w_warehouse_name, ud.d_year DESC
LIMIT 100
