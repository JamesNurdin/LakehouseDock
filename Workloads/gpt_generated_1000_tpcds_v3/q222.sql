WITH inventory_agg AS (
    SELECT inv_item_sk, SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    s.s_store_id,
    s.s_state,
    i.i_class,
    cp.cp_department,
    t_sales.t_hour,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales_net,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(cs.cs_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax) AS net_sales,
    AVG(cs.cs_quantity) AS avg_quantity_sold,
    MAX(inv_agg.total_on_hand) AS total_inventory_on_hand
FROM catalog_sales cs
INNER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
INNER JOIN inventory_agg inv_agg
    ON i.i_item_sk = inv_agg.inv_item_sk
INNER JOIN time_dim t_sales
    ON cs.cs_sold_time_sk = t_sales.t_time_sk
INNER JOIN store_returns sr
    ON i.i_item_sk = sr.sr_item_sk
INNER JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
INNER JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
INNER JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
WHERE
    i.i_class = 'shirts'
    AND cp.cp_department = 'Women'
    AND cs.cs_net_paid_inc_tax > 1000.00
    AND s.s_state = 'CA'
    AND t_sales.t_hour BETWEEN 9 AND 17
    AND inv_agg.total_on_hand >= 300
    AND r.r_reason_desc = 'Damaged'
GROUP BY
    s.s_store_id,
    s.s_state,
    i.i_class,
    cp.cp_department,
    t_sales.t_hour
ORDER BY net_sales DESC
LIMIT 100
