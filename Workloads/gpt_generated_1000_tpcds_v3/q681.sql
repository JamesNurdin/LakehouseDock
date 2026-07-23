WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_manufact_id,
        i.i_color,
        i.i_current_price,
        inv.inv_quantity_on_hand,
        inv.inv_warehouse_sk,
        p.p_promo_id,
        p.p_discount_active,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cp.cp_catalog_page_id,
        cp.cp_department,
        sm.sm_ship_mode_id,
        sm.sm_type,
        w.w_warehouse_id,
        w.w_city,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        st.s_store_id,
        st.s_store_name,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_manufact_id IN (212, 350, 294)
      AND i.i_color IN ('red', 'blue')
      AND cp.cp_department = 'Books'
      AND sm.sm_type = 'Air'
      AND w.w_city = 'New York'
      AND cd.cd_credit_rating = 'Excellent'
)
SELECT
    i_item_sk,
    i_item_id,
    i_brand,
    i_category,
    i_manufact_id,
    i_color,
    i_current_price,
    inv_quantity_on_hand,
    p_promo_id,
    CASE WHEN p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    cs_order_number,
    cs_quantity,
    cs_sales_price,
    cs_net_profit,
    cp_catalog_page_id,
    cp_department,
    sm_ship_mode_id,
    sm_type,
    w_warehouse_id,
    w_city,
    cr_return_quantity,
    cr_return_amount,
    cr_net_loss,
    sr_return_quantity,
    sr_return_amt,
    sr_net_loss,
    s_store_id,
    s_store_name,
    c_customer_id,
    c_first_name,
    c_last_name,
    cd_gender,
    cd_marital_status,
    cd_credit_rating,
    wr_return_quantity,
    wr_return_amt,
    wr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY cs_sales_price DESC) AS sales_price_rank,
    RANK() OVER (PARTITION BY i_item_sk ORDER BY cr_net_loss DESC) AS return_loss_rank,
    SUM(cs_net_profit) OVER (PARTITION BY i_item_sk ORDER BY cs_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM base
ORDER BY cs_sales_price DESC
LIMIT 100
