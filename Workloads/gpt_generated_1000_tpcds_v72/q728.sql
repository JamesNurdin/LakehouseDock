WITH sales_agg AS (
    SELECT
        site.web_site_id,
        site.web_name,
        td.t_hour,
        ca.ca_state,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_ws_net_paid,
        SUM(cs.cs_net_paid) AS total_cs_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        ARRAY_AGG(DISTINCT cd.cd_gender) AS gender_list
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
    JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE
        site.web_mkt_class = 'New'
        AND site.web_company_id IN (1, 3, 5)
        AND ca.ca_street_type = 'Ave'
        AND p.p_channel_catalog = 'N'
        AND td.t_hour BETWEEN 9 AND 17
        AND cs.cs_quantity > 5
        AND ws.ws_quantity > 0
        AND EXISTS (
            SELECT 1 FROM catalog_sales cs_sub
            WHERE cs_sub.cs_sold_date_sk = ws.ws_sold_date_sk
              AND cs_sub.cs_quantity > 10
        )
    GROUP BY
        site.web_site_id,
        site.web_name,
        td.t_hour,
        ca.ca_state,
        cd.cd_gender
    HAVING SUM(ws.ws_net_paid) > 10000
)
SELECT
    web_site_id,
    web_name,
    t_hour,
    ca_state,
    cd_gender,
    total_ws_net_paid,
    total_cs_net_paid,
    distinct_orders,
    gender_list,
    ROW_NUMBER() OVER (PARTITION BY web_site_id ORDER BY total_ws_net_paid DESC) AS rn
FROM sales_agg
ORDER BY total_ws_net_paid DESC
LIMIT 100
