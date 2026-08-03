WITH
    wh_inv AS (
        SELECT
            w.w_warehouse_sk,
            w.w_state,
            w.w_city,
            inv.inv_quantity_on_hand
        FROM warehouse w
        FULL OUTER JOIN inventory inv
            ON inv.inv_warehouse_sk = w.w_warehouse_sk
    ),
    sampled_sales AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
        WHERE ws_sold_date_sk >= 2450000
    )
SELECT
    COALESCE(state, 'ALL') AS state,
    COALESCE(city, 'ALL') AS city,
    SUM(total_return_amount) AS total_return_amount,
    SUM(total_sales_amount) AS total_sales_amount,
    (SELECT MAX(cp_catalog_number) FROM catalog_page) AS max_catalog_number
FROM (
    SELECT
        wi.w_state AS state,
        wi.w_city AS city,
        cr.cr_return_amt_inc_tax AS total_return_amount,
        0.0 AS total_sales_amount
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN wh_inv wi
        ON cr.cr_warehouse_sk = wi.w_warehouse_sk
    WHERE cp.cp_catalog_number > 10
      AND sm.sm_type = 'AIR'
      AND EXISTS (
          SELECT 1 FROM ship_mode sm2 WHERE sm2.sm_type = 'AIR'
      )
    UNION ALL
    SELECT
        wi.w_state AS state,
        wi.w_city AS city,
        0.0 AS total_return_amount,
        wr.wr_return_amt AS total_sales_amount
    FROM web_returns wr
    JOIN sampled_sales ws
        ON ws.ws_item_sk = wr.wr_item_sk
       AND ws.ws_order_number = wr.wr_order_number
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN wh_inv wi
        ON ws.ws_warehouse_sk = wi.w_warehouse_sk
    WHERE sm.sm_type = 'AIR'
      AND wr.wr_return_amt > 0
) sub
GROUP BY GROUPING SETS (
    (state, city),
    (state),
    ()
)
ORDER BY total_return_amount DESC, total_sales_amount DESC
LIMIT 100
