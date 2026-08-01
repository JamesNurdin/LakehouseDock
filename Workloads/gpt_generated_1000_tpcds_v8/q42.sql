WITH site_sales AS (
    SELECT
        web.web_site_sk,
        web.web_name,
        web.web_city,
        SUM(ws.ws_net_profit + cs.cs_net_profit) AS site_total_profit,
        SUM(CASE WHEN p_ws.p_discount_active = 'Y' THEN ws.ws_ext_discount_amt ELSE 0 END) AS site_total_active_discount,
        COUNT(DISTINCT wp.wp_url) AS distinct_pages_visited
    FROM tpcds.web_sales ws
    JOIN tpcds.time_dim td_ws
        ON ws.ws_sold_time_sk = td_ws.t_time_sk
    JOIN tpcds.customer_demographics cd_ws_bill
        ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN tpcds.warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN tpcds.promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_warehouse_sk = w_ws.w_warehouse_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN tpcds.time_dim td_cs
        ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN tpcds.customer_demographics cd_cs_bill
        ON cs.cs_bill_cdemo_sk = cd_cs_bill.cd_demo_sk
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_cdemo_sk = cd_ws_bill.cd_demo_sk
    LEFT JOIN tpcds.time_dim td_sr
        ON sr.sr_return_time_sk = td_sr.t_time_sk
    LEFT JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE web.web_city IN ('Lakeview', 'Pleasant Valley', 'Greenwood')
      AND w_ws.w_warehouse_sq_ft > 50000
      AND cd_ws_bill.cd_gender = 'F'
      AND EXISTS (
          SELECT 1 FROM tpcds.store_returns sr2
          WHERE sr2.sr_cdemo_sk = cd_ws_bill.cd_demo_sk
            AND sr2.sr_return_amt > 200
      )
    GROUP BY web.web_site_sk, web.web_name, web.web_city
)
SELECT
    site_total_profit,
    site_total_active_discount,
    distinct_pages_visited,
    web_name,
    web_city,
    RANK() OVER (ORDER BY site_total_profit DESC) AS profit_rank
FROM site_sales
WHERE site_total_profit > 10000
ORDER BY profit_rank
LIMIT 100
