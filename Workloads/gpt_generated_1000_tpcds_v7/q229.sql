WITH combined_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_state,
        cs.cs_net_profit AS catalog_net_profit,
        ws.ws_net_profit AS web_net_profit
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason rcr
        ON cr.cr_reason_sk = rcr.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason rwr
        ON wr.wr_reason_sk = rwr.r_reason_sk
    WHERE cc.cc_state = 'CA'
      AND ca.ca_country = 'United States'
      AND cs.cs_sales_price > 50
      AND ws.ws_sales_price < 100
)
SELECT
    state,
    customer_id,
    total_profit,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT
        ca_state AS state,
        c_customer_id AS customer_id,
        SUM(COALESCE(catalog_net_profit, 0) + COALESCE(web_net_profit, 0)) AS total_profit
    FROM combined_sales
    GROUP BY ca_state, c_customer_id
) t
ORDER BY state, profit_rank
LIMIT 100
