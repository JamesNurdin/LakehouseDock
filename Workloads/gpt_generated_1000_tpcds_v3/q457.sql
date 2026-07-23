WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_ss.d_year,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS store_sales_profit,
        SUM(COALESCE(cs.cs_net_profit, 0)) AS catalog_sales_profit,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS web_sales_profit,
        SUM(COALESCE(ss.ss_net_profit, 0)) + SUM(COALESCE(cs.cs_net_profit, 0)) + SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
        AND cs.cs_sold_date_sk = d_ss.d_date_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w_cs
        ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_sold_date_sk = d_ss.d_date_sk
    LEFT JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE d_ss.d_year = 2001
      AND s.s_state = 'CA'
      AND cc.cc_company_name = 'able'
    GROUP BY s.s_store_id, s.s_store_name, d_ss.d_year
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    store_sales_profit,
    catalog_sales_profit,
    web_sales_profit,
    total_profit,
    CASE
        WHEN total_profit >= 20000 THEN 'High'
        WHEN total_profit >= 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY profit_rank
LIMIT 100
