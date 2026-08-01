WITH return_agg AS (
    SELECT
        wr_item_sk,
        wr_order_number,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns
    GROUP BY wr_item_sk, wr_order_number
)
SELECT
    i.i_item_sk,
    i.i_product_name,
    sm_cs.sm_type AS ship_mode_cs,
    w_cs.w_warehouse_name AS warehouse_cs,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    COALESCE(rc.return_cnt, 0) AS return_count,
    COALESCE(rc.total_return_amt, 0) AS total_return_amount,
    (
        SELECT AVG(inner_wr.wr_return_amt)
        FROM web_returns inner_wr
        WHERE inner_wr.wr_item_sk = i.i_item_sk
    ) AS avg_return_amt_per_item,
    CASE WHEN EXISTS (
        SELECT 1
        FROM web_returns wr2
        JOIN reason r2 ON wr2.wr_reason_sk = r2.r_reason_sk
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND LOWER(r2.r_reason_desc) LIKE '%size%'
    ) THEN 1 ELSE 0 END AS has_size_related_return
FROM
    store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN return_agg rc ON rc.wr_item_sk = i.i_item_sk AND rc.wr_order_number = ws.ws_order_number
WHERE
    ca_ss.ca_state = 'CA'
GROUP BY
    i.i_item_sk,
    i.i_product_name,
    sm_cs.sm_type,
    w_cs.w_warehouse_name,
    rc.return_cnt,
    rc.total_return_amt
ORDER BY
    catalog_net_profit DESC
LIMIT 100
