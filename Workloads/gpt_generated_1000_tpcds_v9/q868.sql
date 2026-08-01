SELECT
    d_date.d_year AS sales_year,
    d_date.d_month_seq AS month_seq,
    i.i_category AS item_category,
    i.i_brand AS item_brand,
    s.s_state AS store_state,
    p.p_promo_name AS promo_name,
    COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS total_catalog_positive_profit,
    SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_net_profit ELSE 0 END) AS total_store_positive_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_store_tickets,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_return_loss,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
    AVG(p.p_cost) AS avg_promo_cost
FROM
    catalog_sales cs
    INNER JOIN date_dim d_date
        ON cs.cs_sold_date_sk = d_date.d_date_sk
    INNER JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    INNER JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    INNER JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    INNER JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    INNER JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN customer_address ca_store_addr
        ON ss.ss_addr_sk = ca_store_addr.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN customer_address ca_sr_addr
        ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
WHERE
    d_date.d_year = 2001
    AND i.i_size IN ('small', 'medium')
    AND p.p_channel_dmail = 'Y'
    AND w.w_state = 'TX'
    AND s.s_state = 'TX'
    AND inv.inv_quantity_on_hand > 200
    AND t_ss.t_hour BETWEEN 9 AND 17
GROUP BY
    d_date.d_year,
    d_date.d_month_seq,
    i.i_category,
    i.i_brand,
    s.s_state,
    p.p_promo_name
ORDER BY
    d_date.d_year DESC,
    d_date.d_month_seq,
    total_catalog_net_paid DESC
LIMIT 100
