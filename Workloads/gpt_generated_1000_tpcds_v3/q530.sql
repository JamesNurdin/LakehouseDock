WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
),
ws_distinct AS (
    SELECT DISTINCT
        ws_order_number,
        ws_item_sk,
        ws_sold_date_sk
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
),
agg_base AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        w.w_warehouse_name,
        sm.sm_type,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
        i.total_qty_on_hand
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inv_agg i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN ws_distinct ws_dist
        ON ws_dist.ws_order_number = ws.ws_order_number
        AND ws_dist.ws_item_sk = ws.ws_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND sm.sm_type = 'EXPRESS'
        AND cc.cc_gmt_offset = -5.00
        AND cp.cp_catalog_number > 10
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        w.w_warehouse_name,
        sm.sm_type,
        d_sold.d_year,
        d_sold.d_month_seq,
        i.total_qty_on_hand
)
SELECT
    cc_call_center_id,
    cc_name,
    w_warehouse_name,
    sm_type,
    d_year,
    d_month_seq,
    total_catalog_profit,
    total_web_profit,
    total_return_loss,
    total_qty_on_hand,
    CASE
        WHEN total_catalog_profit > (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) THEN 'Above Avg CS Profit'
        ELSE 'Below Avg CS Profit'
    END AS cs_profit_category,
    RANK() OVER (PARTITION BY cc_call_center_id ORDER BY total_catalog_profit DESC) AS profit_rank_by_cc
FROM agg_base
ORDER BY profit_rank_by_cc, total_catalog_profit DESC
LIMIT 100
