/* goal: Summarize total catalog and web sales performance for each brand and state in the year 2001, filtering to larger orders and a specific brand. */
SELECT
    d.d_year AS year,
    i.i_brand AS brand,
    w.w_state AS state,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    SUM(cs.cs_net_paid) AS catalog_total_net_paid,
    AVG(cs.cs_sales_price) AS catalog_avg_sales_price,
    SUM(ws.ws_net_profit) AS web_total_net_profit,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT wr.wr_return_quantity) AS return_cnt,
    SUM(CASE WHEN r.r_reason_desc LIKE '%damaged%' THEN wr.wr_return_amt ELSE 0 END) AS damaged_return_amt
FROM
    catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                      AND inv.inv_item_sk = i.i_item_sk
                      AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site we ON we.web_open_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                      AND ws.ws_item_sk = i.i_item_sk
                      AND ws.ws_warehouse_sk = w.w_warehouse_sk
                      AND ws.ws_web_page_sk = wp.wp_web_page_sk
                      AND ws.ws_web_site_sk = we.web_site_sk
                      AND ws.ws_promo_sk = p.p_promo_sk
                      AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                       AND wr.wr_item_sk = i.i_item_sk
                       AND wr.wr_returned_date_sk = d.d_date_sk
                       AND wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON r.r_reason_sk = wr.wr_reason_sk
WHERE
    d.d_year = 2001
    AND i.i_brand = 'Brand#21'
    AND w.w_state = 'CA'
    AND cs.cs_quantity > 5
GROUP BY
    d.d_year,
    i.i_brand,
    w.w_state
ORDER BY
    d.d_year,
    i.i_brand,
    w.w_state
