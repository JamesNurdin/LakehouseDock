WITH base AS (
    SELECT
        d.d_year,
        d.d_date,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_ext_wholesale_cost,
        ws.ws_net_profit,
        i.i_class_id,
        i.i_color,
        ca.ca_state,
        cd.cd_gender,
        sm.sm_type,
        cc.cc_name,
        s.s_store_id,
        inv.inv_quantity_on_hand,
        sr.sr_ticket_number,
        cr.cr_return_quantity,
        wr.wr_return_quantity,
        td.t_hour
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    LEFT JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_class_id IN (4, 9, 13)
      AND ws.ws_sales_price > 100.00
      AND inv.inv_quantity_on_hand > 0
)
SELECT
    base.d_year,
    base.i_class_id,
    SUM(base.ws_ext_wholesale_cost) AS total_wholesale_cost,
    AVG(base.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT base.ws_order_number) AS distinct_order_cnt,
    COUNT(DISTINCT base.sr_ticket_number) AS distinct_store_return_cnt,
    (SELECT COUNT(*) FROM (
        SELECT ws2.ws_order_number
        FROM tpcds.web_sales ws2
        JOIN tpcds.date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
        INTERSECT
        SELECT cr2.cr_order_number
        FROM tpcds.catalog_returns cr2
        JOIN tpcds.date_dim d3 ON cr2.cr_returned_date_sk = d3.d_date_sk
        WHERE d3.d_year = 2001
    ) AS intersect_set) AS intersect_order_cnt,
    (SELECT COUNT(*) FROM (
        SELECT ws3.ws_order_number
        FROM tpcds.web_sales ws3
        JOIN tpcds.date_dim d4 ON ws3.ws_sold_date_sk = d4.d_date_sk
        WHERE d4.d_year = 2001
        EXCEPT
        SELECT sr3.sr_ticket_number
        FROM tpcds.store_returns sr3
        JOIN tpcds.date_dim d5 ON sr3.sr_returned_date_sk = d5.d_date_sk
        WHERE d5.d_year = 2001
    ) AS except_set) AS except_order_cnt,
    MIN(base.ws_net_profit) AS min_net_profit,
    MAX(base.ws_net_profit) AS max_net_profit
FROM base
WHERE base.ws_sales_price > (
    SELECT AVG(ws4.ws_sales_price)
    FROM tpcds.web_sales ws4
    JOIN tpcds.date_dim d6 ON ws4.ws_sold_date_sk = d6.d_date_sk
    WHERE d6.d_year = 2000
)
GROUP BY base.d_year, base.i_class_id
ORDER BY total_wholesale_cost DESC
LIMIT 100
