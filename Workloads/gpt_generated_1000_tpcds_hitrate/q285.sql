WITH
    inv_agg AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            inv_date_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand,
            COUNT(*) AS inv_record_cnt
        FROM inventory
        GROUP BY inv_item_sk, inv_warehouse_sk, inv_date_sk
    ),
    dummy_set AS (
        SELECT 1 AS dummy_flag UNION ALL SELECT 2
    )
SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    COUNT(DISTINCT ss.ss_ticket_number)                                   AS total_store_sales,
    SUM(ss.ss_net_paid)                                                    AS total_store_net_paid,
    SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_net_profit ELSE 0 END)   AS total_positive_store_profit,
    COUNT(DISTINCT cs.cs_order_number)                                      AS total_catalog_orders,
    SUM(cs.cs_ext_sales_price)                                              AS total_catalog_sales,
    SUM(cr.cr_net_loss)                                                     AS total_catalog_return_loss,
    SUM(wr.wr_net_loss)                                                     AS total_web_return_loss,
    SUM(p.p_cost)                                                          AS total_promo_cost,
    COUNT(DISTINCT r.r_reason_sk)                                          AS distinct_return_reasons,
    SUM(i.total_qty_on_hand)                                               AS total_inventory_qty_on_hand,
    CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END               AS store_profit_category
FROM date_dim d_sales
RIGHT JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN time_dim t_sales
    ON ss.ss_sold_time_sk = t_sales.t_time_sk
LEFT JOIN household_demographics hd_store
    ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
LEFT JOIN customer_address ca_store
    ON ss.ss_addr_sk = ca_store.ca_address_sk
LEFT JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk

-- catalog sales and its dimensions
LEFT JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_sales.d_date_sk
LEFT JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
LEFT JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk

-- catalog returns and its dimensions
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
LEFT JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
LEFT JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk

-- web returns and its dimensions
LEFT JOIN web_returns wr
    ON wr.wr_order_number = cs.cs_order_number
   AND wr.wr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN household_demographics hd_wr_refunded
    ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
LEFT JOIN customer_address ca_wr_refunded
    ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
LEFT JOIN household_demographics hd_wr_returning
    ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
LEFT JOIN customer_address ca_wr_returning
    ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk

-- inventory aggregation joined to catalog sales item and to its date dimension
LEFT JOIN inv_agg i
    ON i.inv_item_sk = cs.cs_item_sk
LEFT JOIN date_dim d_inventory
    ON i.inv_date_sk = d_inventory.d_date_sk

-- promotion start and end dates (aliased differently)
LEFT JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
LEFT JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk

CROSS JOIN dummy_set ds
WHERE d_sales.d_year = 2000
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    d_sales.d_date,
    CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END
ORDER BY
    d_sales.d_year DESC,
    total_store_sales DESC
LIMIT 100
