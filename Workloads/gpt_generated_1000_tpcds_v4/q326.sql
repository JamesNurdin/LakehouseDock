WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(SUM(cs.cs_net_profit), 0) AS catalog_net_profit,
        COALESCE(SUM(ss.ss_net_profit), 0) AS store_net_profit,
        COALESCE(SUM(ws.ws_net_profit), 0) AS web_net_profit,
        COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0) + COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM
        item i
        LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name
)
SELECT DISTINCT
    i_sales.i_item_id,
    i_sales.i_product_name,
    c.cc_name AS call_center_name,
    cp.cp_department,
    w.w_warehouse_name,
    td.t_hour,
    i_sales.total_net_profit,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY i_sales.total_net_profit DESC) AS profit_rank,
    CASE
        WHEN i_sales.total_net_profit > 10000 THEN 'High'
        WHEN i_sales.total_net_profit > 5000  THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM
    item_sales i_sales
    JOIN catalog_sales cs ON cs.cs_item_sk = i_sales.i_item_sk
    JOIN call_center c ON c.cc_call_center_sk = cs.cs_call_center_sk
    JOIN catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer cu ON cu.c_customer_sk = cs.cs_bill_customer_sk
    JOIN customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
    JOIN store_sales ss ON ss.ss_item_sk = i_sales.i_item_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i_sales.i_item_sk
    JOIN time_dim td ON td.t_time_sk = cs.cs_sold_time_sk
    JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN web_sales ws ON ws.ws_item_sk = i_sales.i_item_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
WHERE
    c.cc_market_manager = 'John Doe'                -- filter 1
    AND w.w_state = 'CA'                             -- filter 2
    AND td.t_hour BETWEEN 9 AND 17                  -- filter 3
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_quantity > 0
    )
ORDER BY
    i_sales.total_net_profit DESC,
    profit_rank
LIMIT 100
