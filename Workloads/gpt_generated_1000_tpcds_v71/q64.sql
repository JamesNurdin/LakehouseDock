WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_order_number,
        cs.cs_catalog_page_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_quantity
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
      AND cs.cs_sold_date_sk BETWEEN 2451911 AND 2452275   -- surrogate date range example
)
SELECT
    i.i_category               AS category,
    s.s_state                  AS state,
    t_sold.t_hour              AS hour,
    SUM(sb.cs_ext_sales_price) AS total_sales,
    SUM(cr.cr_net_loss)        AS total_return_loss,
    SUM(sr.sr_return_amt)      AS total_store_return,
    COUNT(DISTINCT sb.cs_order_number) AS order_cnt,
    (
        SELECT MAX(i2.i_current_price)
        FROM item i2
        WHERE i2.i_category = i.i_category
    )                           AS max_price_in_category
FROM sales_base sb
JOIN catalog_page cp
    ON sb.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
    ON sb.cs_item_sk = i.i_item_sk
JOIN warehouse w
    ON sb.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t_sold
    ON sb.cs_sold_time_sk = t_sold.t_time_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = sb.cs_order_number
JOIN catalog_page cp_ret
    ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
JOIN warehouse w_ret
    ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
JOIN household_demographics hd_refund
    ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN household_demographics hd_store
    ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
JOIN customer_address ca_store
    ON sr.sr_addr_sk = ca_store.ca_address_sk
JOIN time_dim t_sr
    ON sr.sr_return_time_sk = t_sr.t_time_sk
WHERE i.i_category = 'hockey'
  AND s.s_state = 'CA'
  AND w.w_city = 'Seattle'
  AND cp.cp_department = 'Sports'
  AND i.i_rec_start_date > DATE '2000-01-01'
  AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_warehouse_sk = w.w_warehouse_sk
    )
GROUP BY ROLLUP (i.i_category, s.s_state, t_sold.t_hour)
ORDER BY total_sales DESC
