WITH joined_data AS (
    SELECT
        w.w_warehouse_id AS w_warehouse_id,
        w.w_state AS w_state,
        p.p_promo_id AS p_promo_id,
        d_sold.d_year AS sold_year,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cr.cr_net_loss,
        sr.sr_net_loss AS store_return_net_loss,
        inv.inv_quantity_on_hand,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret
      ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN store_returns sr
      ON sr.sr_customer_sk = c.c_customer_sk
     AND sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN inventory inv
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
     AND inv.inv_date_sk = d_ret.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND w.w_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND c.c_preferred_cust_flag = 'Y'
        AND cd.cd_dep_employed_count >= 3
        AND inv.inv_quantity_on_hand > 0
)
SELECT
    w_warehouse_id,
    w_state,
    p_promo_id,
    sold_year,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cr_net_loss) AS total_catalog_return_loss,
    SUM(store_return_net_loss) AS total_store_return_loss,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
FROM joined_data
GROUP BY
    w_warehouse_id,
    w_state,
    p_promo_id,
    sold_year
ORDER BY total_net_profit DESC
LIMIT 100
