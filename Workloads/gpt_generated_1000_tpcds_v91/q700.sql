WITH sampled_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (5)
)
SELECT
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    d_sales.d_year,
    p_sales.p_promo_name,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_return_loss,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS store_sales_profit_flag,
    (
        SELECT COUNT(*)
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_item_sk = i.i_item_sk
          AND cs_sub.cs_sold_date_sk > d_sales.d_date_sk
    ) AS future_catalog_sales_cnt
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN household_demographics hd_sales
    ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN customer_address ca_sales
    ON ss.ss_addr_sk = ca_sales.ca_address_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_item_sk = i.i_item_sk
LEFT JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN promotion p_sales
    ON ss.ss_promo_sk = p_sales.p_promo_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_cat
    ON cs.cs_sold_date_sk = d_cat.d_date_sk
JOIN promotion p_cat
    ON cs.cs_promo_sk = p_cat.p_promo_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w_cat
    ON cs.cs_warehouse_sk = w_cat.w_warehouse_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws
    ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND wr.wr_item_sk = i.i_item_sk
LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN sampled_inventory inv
    ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
JOIN warehouse w_inv
    ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
GROUP BY
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    d_sales.d_year,
    p_sales.p_promo_name,
    i.i_item_sk,
    d_sales.d_date_sk
ORDER BY total_store_net_paid DESC
LIMIT 100
