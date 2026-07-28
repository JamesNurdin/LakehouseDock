WITH sales_agg AS (
    SELECT
        i.i_category,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
        SUM(cs.cs_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0)) AS profit_minus_loss,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_status
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY i.i_category, w.w_warehouse_name
)
SELECT
    i_category,
    w_warehouse_name,
    total_profit,
    total_return_loss,
    profit_minus_loss,
    profit_status,
    RANK() OVER (PARTITION BY i_category ORDER BY profit_minus_loss DESC) AS profit_rank
FROM sales_agg
ORDER BY profit_minus_loss DESC
LIMIT 100
