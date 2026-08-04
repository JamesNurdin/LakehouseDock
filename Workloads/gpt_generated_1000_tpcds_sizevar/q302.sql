WITH intersect_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    INTERSECT
    SELECT ws.ws_order_number
    FROM web_sales ws
)
SELECT
    ROW_NUMBER() OVER (ORDER BY d_cs.d_year, s.s_store_id) AS row_num,
    s.s_store_id,
    d_cs.d_year,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
FROM
    catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN store s ON s.s_closed_date_sk = d_cs.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d_cs.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    JOIN web_sales ws ON cs.cs_order_number = ws.ws_order_number
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    d_cs.d_year = 2001
    AND cs.cs_order_number IN (SELECT order_number FROM intersect_orders)
    AND NOT EXISTS (
        SELECT 1
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
          AND inv2.inv_date_sk = d_cs.d_date_sk
          AND inv2.inv_quantity_on_hand = 0
    )
GROUP BY
    s.s_store_id,
    d_cs.d_year
ORDER BY
    d_cs.d_year,
    s.s_store_id
