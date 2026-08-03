WITH blue_items AS (
    SELECT DISTINCT i_item_sk, i_category, i_brand
    FROM item
    WHERE i_formulation LIKE '%blue%'
)
SELECT
    sm.sm_ship_mode_id,
    i.i_category,
    SUM(cs.cs_net_profit) AS catalog_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS catalog_return_amount,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS store_return_amount,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS web_return_amount,
    (
        SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) -
        SUM(COALESCE(cr.cr_return_amount, 0)) -
        SUM(COALESCE(sr.sr_return_amt, 0)) -
        SUM(COALESCE(wr.wr_return_amt, 0))
    ) AS total_net,
    CASE
        WHEN (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit)) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status,
    (
        SELECT MAX(i2.i_wholesale_cost)
        FROM item i2
        WHERE i2.i_class_id = i.i_class_id
    ) AS max_wholesale_cost,
    ROW_NUMBER() OVER (
        PARTITION BY sm.sm_ship_mode_id
        ORDER BY (
            SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) -
            SUM(COALESCE(cr.cr_return_amount, 0)) -
            SUM(COALESCE(sr.sr_return_amt, 0)) -
            SUM(COALESCE(wr.wr_return_amt, 0))
        ) DESC
    ) AS profit_rank
FROM catalog_sales cs
RIGHT OUTER JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN blue_items bi
    ON i.i_item_sk = bi.i_item_sk
LEFT JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
LEFT JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws
    ON cs.cs_item_sk = ws.ws_item_sk AND cs.cs_order_number = ws.ws_order_number
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
LEFT JOIN store_returns sr
    ON cs.cs_item_sk = sr.sr_item_sk
WHERE bi.i_item_sk IS NOT NULL
GROUP BY
    sm.sm_ship_mode_id,
    i.i_category,
    i.i_class_id
ORDER BY total_net DESC
LIMIT 100
