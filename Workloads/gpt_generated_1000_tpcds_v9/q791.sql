/*
Goal: Aggregate sales, returns, inventory and store‑sales metrics by item category and year, showing promotion status and high‑value sales, while joining all 15 selected TPC‑DS tables with deep relationships and re‑using dimensions under different aliases.
*/
WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_customer_sk,
        cs.cs_order_number,
        SUM(cs.cs_net_paid_inc_tax)        AS total_net_paid,
        SUM(cs.cs_quantity)                AS total_quantity,
        SUM(cs.cs_ext_discount_amt)        AS total_discount
    FROM catalog_sales cs
    GROUP BY
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_customer_sk,
        cs.cs_order_number
),
inv_agg AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_date_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_date_sk
)
SELECT
    d_sale.d_year                                               AS sale_year,
    i.i_category,
    i.i_brand,
    CASE WHEN i.i_category = 'Electronics' THEN 'E' ELSE 'Other' END AS category_group,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    SUM(ca.total_net_paid)                                      AS total_sales_amount,
    SUM(ca.total_quantity)                                      AS total_units_sold,
    SUM(inv_agg.total_on_hand)                                  AS total_inventory_on_hand,
    SUM(ss.ss_net_paid)                                         AS total_store_sales_amount,
    SUM(ss.ss_quantity)                                         AS total_store_units_sold,
    SUM(cr.cr_return_amount)                                    AS total_return_amount,
    SUM(CASE WHEN ca.total_net_paid > 1000 THEN ca.total_net_paid ELSE 0 END) AS high_value_sales_amount
FROM cs_agg ca
JOIN item i
    ON ca.cs_item_sk = i.i_item_sk
JOIN date_dim d_sale
    ON ca.cs_sold_date_sk = d_sale.d_date_sk
JOIN call_center cc
    ON ca.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
    ON ca.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp
    ON ca.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c
    ON ca.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca_addr
    ON c.c_current_addr_sk = ca_addr.ca_address_sk
LEFT JOIN inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
   AND inv_agg.inv_date_sk = d_sale.d_date_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN time_dim t_store
    ON ss.ss_sold_time_sk = t_store.t_time_sk
JOIN promotion p2
    ON ss.ss_promo_sk = p2.p_promo_sk
JOIN customer c2
    ON ss.ss_customer_sk = c2.c_customer_sk
JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
LEFT JOIN catalog_returns cr
    ON ca.cs_order_number = cr.cr_order_number
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN call_center cc_ret
    ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
LEFT JOIN catalog_page cp_ret
    ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
LEFT JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return
    ON cr.cr_returned_time_sk = t_return.t_time_sk
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_wp_create
    ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
LEFT JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d_sale.d_date_sk
LEFT JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
GROUP BY
    d_sale.d_year,
    i.i_category,
    i.i_brand,
    CASE WHEN i.i_category = 'Electronics' THEN 'E' ELSE 'Other' END,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END
ORDER BY total_sales_amount DESC
LIMIT 100
