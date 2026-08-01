WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_ext_tax,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_units,
        i.i_rec_end_date,
        sm.sm_ship_mode_id,
        td.t_hour,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    WHERE i.i_units = 'Case'
      AND i.i_rec_end_date > DATE '2000-01-01'
      AND cs.cs_ext_tax > 5.00
)
SELECT
    sd.i_item_id,
    sd.i_product_name,
    sd.i_category,
    sd.sm_ship_mode_id,
    SUM(sd.cs_net_paid_inc_ship_tax) AS total_catalog_net,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(ws.ws_net_paid_inc_ship_tax) AS total_web_net,
    SUM(wr.wr_return_amt) AS total_web_returns,
    AVG(sd.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT sd.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    CASE
        WHEN COALESCE(SUM(cr.cr_return_quantity), 0) = 0 THEN 'No Return'
        ELSE 'Returned'
    END AS return_flag,
    ROW_NUMBER() OVER (PARTITION BY sd.i_category ORDER BY SUM(sd.cs_net_paid_inc_ship_tax) DESC) AS profit_rank
FROM sales_data sd
LEFT JOIN catalog_returns cr
    ON sd.cs_order_number = cr.cr_order_number
   AND sd.cs_item_sk = cr.cr_item_sk
LEFT JOIN web_sales ws
    ON sd.cs_item_sk = ws.ws_item_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
JOIN ship_mode sm_web
    ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk
JOIN time_dim td_web
    ON ws.ws_sold_time_sk = td_web.t_time_sk
WHERE ws.ws_ship_customer_sk = 11185919
GROUP BY
    sd.i_item_id,
    sd.i_product_name,
    sd.i_category,
    sd.sm_ship_mode_id
ORDER BY total_catalog_net DESC
LIMIT 100
