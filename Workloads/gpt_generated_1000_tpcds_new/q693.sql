WITH
    sales_keys AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        WHERE cs.cs_ext_ship_cost > 600
    ),
    coupon_keys AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        WHERE cs.cs_coupon_amt = 0
    ),
    order_diff AS (
        SELECT cs_order_number
        FROM sales_keys
        EXCEPT
        SELECT cs_order_number
        FROM coupon_keys
    ),
    base AS (
        SELECT
            cs.cs_order_number,
            cs.cs_ext_ship_cost,
            cs.cs_net_paid,
            cs.cs_net_profit,
            cp.cp_catalog_page_id,
            td.t_hour,
            cd.cd_education_status,
            ws.ws_net_paid_inc_ship,
            ws.ws_web_site_sk,
            wsi.web_site_sk AS wsit_sk
        FROM catalog_sales cs
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN time_dim td
            ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN web_sales ws
            ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN web_site wsi
            ON ws.ws_web_site_sk = wsi.web_site_sk
        WHERE cp.cp_type = 'Catalog'
          AND cd.cd_education_status = 'College'
          AND cs.cs_ext_ship_cost > 500
          AND ws.ws_net_paid_inc_ship > 5000
          AND cs.cs_order_number IN (SELECT cs_order_number FROM order_diff)
    ),
    subset1 AS (
        SELECT * FROM base WHERE t_hour < 12
    ),
    subset2 AS (
        SELECT * FROM base WHERE t_hour >= 12
    ),
    unioned AS (
        SELECT * FROM subset1
        UNION
        SELECT * FROM subset2
    )
SELECT
    cp_catalog_page_id,
    cd_education_status,
    t_hour,
    COUNT(DISTINCT cs_order_number) AS orders_cnt,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(ws_net_paid_inc_ship) AS avg_ws_net_paid_inc_ship,
    MAX(cs_ext_ship_cost) AS max_ship_cost,
    CASE WHEN SUM(cs_net_profit) > 0 THEN 'Overall Profit' ELSE 'Overall Loss' END AS overall_profit_flag,
    (
        SELECT MAX(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = unioned.wsit_sk
    ) AS max_site_net_paid
FROM unioned
GROUP BY cp_catalog_page_id, cd_education_status, t_hour, wsit_sk
ORDER BY total_net_paid DESC
LIMIT 100
