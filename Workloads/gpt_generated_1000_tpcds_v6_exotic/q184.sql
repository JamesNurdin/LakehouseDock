WITH base AS (
    SELECT
        cs.cs_order_number               AS order_number,
        ds_sold.d_date                    AS sold_date,
        ds_ship.d_date                    AS ship_date,
        i.i_item_id                       AS i_item_id,
        i.i_product_name                  AS i_product_name,
        i.i_class_id                      AS class_id,
        i.i_manager_id                    AS manager_id,
        cp.cp_catalog_number              AS catalog_number,
        cp.cp_department                  AS department,
        cs.cs_net_paid                    AS net_paid,
        cs.cs_net_profit                  AS net_profit,
        sr.sr_return_quantity             AS return_quantity,
        sr.sr_return_amt                  AS return_amount,
        wp.wp_url                         AS web_page_url,
        cust_bill.c_customer_id           AS bill_customer_id,
        cust_ship.c_customer_id           AS ship_customer_id,
        w.w_warehouse_name                AS warehouse_name,
        w.w_state                         AS warehouse_state,
        s.s_store_name                    AS store_name,
        p.p_promo_name                    AS promo_name,
        sm.sm_type                        AS ship_mode_type,
        dr_returned.d_date                AS return_date
    FROM catalog_sales cs
    JOIN date_dim ds_sold
        ON cs.cs_sold_date_sk = ds_sold.d_date_sk
    JOIN date_dim ds_ship
        ON cs.cs_ship_date_sk = ds_ship.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    LEFT JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
           AND sr.sr_customer_sk = cust_bill.c_customer_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim dr_returned
        ON sr.sr_returned_date_sk = dr_returned.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = cust_bill.c_customer_sk
           AND wp.wp_creation_date_sk = ds_sold.d_date_sk
    WHERE ds_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_class_id = 14
      AND i.i_manager_id IN (4, 11)
      AND p.p_purpose = 'Unknown'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND cp.cp_department = 'Electronics'
)
SELECT
    order_number,
    sold_date,
    ship_date,
    i_item_id,
    i_product_name,
    catalog_number,
    net_paid,
    net_profit,
    return_quantity,
    return_amount,
    web_page_url,
    RANK() OVER (PARTITION BY class_id ORDER BY net_profit DESC) AS profit_rank
FROM base
ORDER BY profit_rank, net_profit DESC
LIMIT 100
