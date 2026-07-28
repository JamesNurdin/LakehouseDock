WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        cp.cp_department,
        w.w_warehouse_id,
        t.t_hour,
        c.c_salutation,
        cd.cd_gender,
        ws.ws_web_site_sk,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        wp.wp_web_page_id,
        web_s.web_state,
        inv.inv_quantity_on_hand,
        cr.cr_return_amount,
        wr.wr_return_amt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_order_number = cs.cs_order_number
                      AND ws.ws_item_sk = cs.cs_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web_s ON ws.ws_web_site_sk = web_s.web_site_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                              AND wr.wr_item_sk = ws.ws_item_sk
    WHERE cp.cp_type = 'monthly'
      AND c.c_salutation = 'Mr.'
      AND t.t_hour BETWEEN 9 AND 17
      AND wp.wp_rec_start_date >= DATE '2023-01-01'
      AND wp.wp_rec_end_date < DATE '2024-01-01'
      AND NOT EXISTS (
          SELECT 1 FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cs.cs_order_number
            AND cr2.cr_item_sk = cs.cs_item_sk
      )
)
SELECT
    jd.w_warehouse_id,
    jd.cp_department,
    jd.web_state,
    SUM(jd.cs_net_paid) AS total_catalog_net_paid,
    SUM(jd.ws_net_paid) AS total_web_net_paid,
    COUNT(DISTINCT jd.cs_order_number) AS distinct_orders,
    AVG(jd.cs_ext_discount_amt) AS avg_catalog_discount,
    SUM(jd.inv_quantity_on_hand) AS total_inventory_on_hand,
    (SELECT AVG(cs_ext_discount_amt) FROM catalog_sales) AS overall_avg_discount,
    RANK() OVER (PARTITION BY jd.w_warehouse_id ORDER BY SUM(jd.cs_net_paid) DESC) AS sales_rank_in_warehouse
FROM joined_data jd
GROUP BY jd.w_warehouse_id, jd.cp_department, jd.web_state
HAVING SUM(jd.cs_net_paid) > 10000
ORDER BY total_catalog_net_paid DESC
LIMIT 100
