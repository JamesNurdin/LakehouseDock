WITH sales_summary AS (
    SELECT
        cc.cc_name,
        i.i_category,
        p.p_promo_name,
        w.w_city,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM tpcds.call_center cc
    INNER JOIN tpcds.catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    INNER JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN tpcds.web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_category = 'Sports'
      AND p.p_channel_press = 'N'
      AND cp.cp_department = 'DEPARTMENT'
      AND w.w_country = 'United States'
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451179
      AND ss.ss_quantity > 1
    GROUP BY
        cc.cc_name,
        i.i_category,
        p.p_promo_name,
        w.w_city
)
SELECT
    city,
    AVG(total_net_profit) AS avg_total_net_profit,
    SUM(total_orders) AS total_orders
FROM (
    SELECT
        w_city AS city,
        (catalog_net_profit + store_net_profit + web_net_profit) AS total_net_profit,
        order_cnt AS total_orders
    FROM sales_summary
) agg
GROUP BY city
HAVING SUM(total_orders) > 10
ORDER BY avg_total_net_profit DESC
LIMIT 20
