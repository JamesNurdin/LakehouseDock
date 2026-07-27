WITH base_sales AS (
    SELECT DISTINCT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        t.t_hour,
        i.i_category,
        p.p_promo_name,
        cc.cc_name,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name
    FROM catalog_sales cs
    JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND i.i_category = 'Electronics'
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND cp.cp_department = 'Sports'
)
SELECT DISTINCT
    bs.cs_order_number,
    bs.cs_net_profit,
    bs.i_category,
    bs.p_promo_name,
    bs.cc_name,
    bs.cp_department,
    cr.cr_return_amount,
    inv.inv_quantity_on_hand,
    ss.ss_net_paid,
    ws.ws_net_paid,
    wp.wp_type,
    ws_site.web_name,
    RANK() OVER (PARTITION BY bs.cs_bill_customer_sk ORDER BY bs.cs_net_profit DESC) AS profit_rank,
    CASE
        WHEN bs.cs_net_profit > (
            SELECT AVG(cs_net_profit)
            FROM catalog_sales
            WHERE cs_item_sk = bs.cs_item_sk
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg
FROM base_sales bs
LEFT JOIN catalog_returns cr
       ON cr.cr_order_number = bs.cs_order_number
LEFT JOIN inventory inv
       ON inv.inv_item_sk = bs.cs_item_sk
      AND inv.inv_warehouse_sk = bs.cs_warehouse_sk
LEFT JOIN store_sales ss
       ON ss.ss_item_sk = bs.cs_item_sk
      AND ss.ss_customer_sk = bs.cs_bill_customer_sk
LEFT JOIN web_sales ws
       ON ws.ws_item_sk = bs.cs_item_sk
      AND ws.ws_bill_customer_sk = bs.cs_bill_customer_sk
LEFT JOIN web_page wp
       ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site ws_site
       ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE cr.cr_return_quantity IS NULL
GROUP BY
    bs.cs_order_number,
    bs.cs_net_profit,
    bs.i_category,
    bs.p_promo_name,
    bs.cc_name,
    bs.cp_department,
    cr.cr_return_amount,
    inv.inv_quantity_on_hand,
    ss.ss_net_paid,
    ws.ws_net_paid,
    wp.wp_type,
    ws_site.web_name,
    bs.cs_bill_customer_sk,
    bs.cs_item_sk
ORDER BY profit_rank ASC, bs.cs_net_profit DESC
LIMIT 100
