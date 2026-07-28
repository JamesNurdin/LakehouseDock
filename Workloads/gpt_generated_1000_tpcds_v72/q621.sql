/* goal: Calculate total net profit and return amount per catalog page, store and warehouse for 2001, classifying profit levels, ranking pages by profit, and showing average inventory for each warehouse */
WITH base AS (
    SELECT
        cp.cp_catalog_page_number,
        cp.cp_department,
        s.s_store_name,
        w.w_warehouse_sk,
        w.w_state,
        sm.sm_type,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        i.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_date_sk = d_sold.d_date_sk
    JOIN web_returns wr ON wr.wr_order_number = cs.cs_order_number
        AND wr.wr_item_sk = cs.cs_item_sk
    JOIN date_dim d_web_ret ON wr.wr_returned_date_sk = d_web_ret.d_date_sk
    WHERE d_sold.d_year = 2001
      AND p.p_channel_email = 'Y'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND s.s_country = 'United States'
      AND cp.cp_department = 'Electronics'
      AND i.inv_quantity_on_hand > 0
    GROUP BY
        cp.cp_catalog_page_number,
        cp.cp_department,
        s.s_store_name,
        w.w_warehouse_sk,
        w.w_state,
        sm.sm_type,
        p.p_promo_name,
        i.inv_quantity_on_hand
)
SELECT
    cp_catalog_page_number,
    cp_department,
    s_store_name,
    w_state,
    sm_type,
    p_promo_name,
    total_net_profit,
    total_return_amount,
    CASE
        WHEN total_net_profit > 100000 THEN 'High'
        WHEN total_net_profit > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    (SELECT AVG(i2.inv_quantity_on_hand)
     FROM inventory i2
     WHERE i2.inv_warehouse_sk = base.w_warehouse_sk) AS avg_warehouse_inventory,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM base
ORDER BY total_net_profit DESC
LIMIT 100
