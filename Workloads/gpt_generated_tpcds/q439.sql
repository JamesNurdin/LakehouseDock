WITH cs_agg AS (
    SELECT
        d_cs.d_year,
        d_cs.d_month_seq,
        i.i_category,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS cs_net_profit,
        SUM(cs.cs_quantity) AS cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d_cs.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d_cs.d_year, d_cs.d_month_seq, i.i_category, w.w_warehouse_name
),
ws_agg AS (
    SELECT
        d_ws.d_year,
        d_ws.d_month_seq,
        i.i_category,
        w.w_warehouse_name,
        SUM(ws.ws_net_profit) AS ws_net_profit,
        SUM(ws.ws_quantity) AS ws_quantity
    FROM web_sales ws
    JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d_ws.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d_ws.d_year, d_ws.d_month_seq, i.i_category, w.w_warehouse_name
),
inv_agg AS (
    SELECT
        d_inv.d_year,
        d_inv.d_month_seq,
        i.i_category,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS inv_quantity_on_hand
    FROM inventory inv
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d_inv.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d_inv.d_year, d_inv.d_month_seq, i.i_category, w.w_warehouse_name
)
SELECT
    COALESCE(cs_agg.d_year, ws_agg.d_year, inv_agg.d_year) AS d_year,
    COALESCE(cs_agg.d_month_seq, ws_agg.d_month_seq, inv_agg.d_month_seq) AS d_month_seq,
    COALESCE(cs_agg.i_category, ws_agg.i_category, inv_agg.i_category) AS i_category,
    COALESCE(cs_agg.w_warehouse_name, ws_agg.w_warehouse_name, inv_agg.w_warehouse_name) AS w_warehouse_name,
    cs_agg.cs_net_profit,
    ws_agg.ws_net_profit,
    inv_agg.inv_quantity_on_hand
FROM cs_agg
FULL OUTER JOIN ws_agg
    ON cs_agg.d_year = ws_agg.d_year
    AND cs_agg.d_month_seq = ws_agg.d_month_seq
    AND cs_agg.i_category = ws_agg.i_category
    AND cs_agg.w_warehouse_name = ws_agg.w_warehouse_name
FULL OUTER JOIN inv_agg
    ON COALESCE(cs_agg.d_year, ws_agg.d_year) = inv_agg.d_year
    AND COALESCE(cs_agg.d_month_seq, ws_agg.d_month_seq) = inv_agg.d_month_seq
    AND COALESCE(cs_agg.i_category, ws_agg.i_category) = inv_agg.i_category
    AND COALESCE(cs_agg.w_warehouse_name, ws_agg.w_warehouse_name) = inv_agg.w_warehouse_name
ORDER BY d_year, d_month_seq, i_category, w_warehouse_name
