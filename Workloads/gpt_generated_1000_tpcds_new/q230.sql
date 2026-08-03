WITH sales_agg AS (
    SELECT cs_item_sk,
           SUM(cs_net_paid) AS total_net_paid,
           COUNT(*)       AS sales_cnt
    FROM catalog_sales
    GROUP BY cs_item_sk
)
SELECT
    cc.cc_name,
    w_sales.w_warehouse_name,
    i_sales.i_product_name,
    r.r_reason_desc,
    COUNT(DISTINCT cs.cs_order_number)               AS distinct_orders,
    SUM(DISTINCT cr.cr_return_amount)                AS distinct_return_amount,
    sales_agg.total_net_paid,
    (SELECT AVG(i2.i_current_price) FROM item i2)    AS avg_item_price
FROM catalog_sales cs
JOIN time_dim td            ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer c_bill        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN call_center cc         ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w_sales      ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
JOIN item i_sales           ON cs.cs_item_sk = i_sales.i_item_sk
JOIN sales_agg              ON i_sales.i_item_sk = sales_agg.cs_item_sk
JOIN catalog_returns cr    ON cs.cs_order_number = cr.cr_order_number
JOIN reason r               ON cr.cr_reason_sk = r.r_reason_sk
JOIN inventory inv          ON i_sales.i_item_sk = inv.inv_item_sk
JOIN web_returns wr        ON wr.wr_returned_time_sk = td.t_time_sk
JOIN item i_return          ON wr.wr_item_sk = i_return.i_item_sk
WHERE cc.cc_rec_start_date > DATE '2000-01-01'
GROUP BY
    cc.cc_name,
    w_sales.w_warehouse_name,
    i_sales.i_product_name,
    r.r_reason_desc,
    sales_agg.total_net_paid
ORDER BY distinct_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
