WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(cs.cs_quantity) AS catalog_quantity,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk

    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd_store
        ON ss.ss_cdemo_sk = cd_store.cd_demo_sk

    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd_web_bill
        ON ws.ws_bill_cdemo_sk = cd_web_bill.cd_demo_sk
    JOIN ship_mode sm_web
        ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk

    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN customer_demographics cd_refund
        ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk

    WHERE td.t_meal_time = 'lunch'
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT
    sa.i_item_id,
    sa.i_product_name,
    sa.catalog_net_paid,
    sa.store_net_paid,
    sa.web_net_paid,
    (sa.catalog_net_paid + sa.store_net_paid + sa.web_net_paid) AS total_net_paid,
    ROW_NUMBER() OVER (ORDER BY (sa.catalog_net_paid + sa.store_net_paid + sa.web_net_paid) DESC) AS revenue_rank
FROM sales_agg sa
ORDER BY total_net_paid DESC
LIMIT 100
