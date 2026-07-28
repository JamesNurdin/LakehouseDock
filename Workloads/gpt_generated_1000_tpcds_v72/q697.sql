WITH joined_data AS (
    SELECT
        cs.cs_net_paid AS catalog_net_paid,
        cs.cs_net_paid_inc_tax AS catalog_net_paid_inc_tax,
        ss.ss_net_paid AS store_net_paid,
        ss.ss_net_profit AS store_net_profit,
        sr.sr_net_loss AS store_return_net_loss,
        w.w_state AS w_state,
        ca.ca_state AS ca_state,
        wp.wp_type AS wp_type,
        wp.wp_autogen_flag,
        wp.wp_image_count,
        cs.cs_sales_price,
        cs.cs_quantity AS cs_quantity,
        ss.ss_quantity AS ss_quantity,
        sr.sr_return_quantity
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wp.wp_image_count >= 3
      AND w.w_street_name = 'Oak Ninth'
      AND ca.ca_state = 'CA'
      AND c.c_birth_day = 7
      AND wp.wp_rec_start_date >= DATE '2023-01-01'
      AND cs.cs_sales_price > 100
)
SELECT
    w_state,
    ca_state,
    wp_type,
    SUM(catalog_net_paid) AS sum_catalog_net_paid,
    SUM(store_net_paid) AS sum_store_net_paid,
    SUM(store_return_net_loss) AS sum_return_net_loss,
    COUNT(*) AS txn_count
FROM joined_data
GROUP BY GROUPING SETS (
    (w_state, ca_state, wp_type),
    (w_state, ca_state),
    (w_state, wp_type),
    (ca_state, wp_type),
    (w_state),
    (ca_state),
    (wp_type),
    ()
)
ORDER BY w_state NULLS LAST, ca_state NULLS LAST, wp_type NULLS LAST
LIMIT 100
