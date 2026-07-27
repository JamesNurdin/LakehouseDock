WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d_sales.d_year,
    s.s_store_name,
    r.r_reason_desc,
    SUM(cs.cs_net_paid)               AS total_catalog_sales,
    SUM(ss.ss_net_paid)               AS total_store_sales,
    SUM(cr.cr_net_loss)               AS total_catalog_return_loss,
    SUM(sr.sr_net_loss)               AS total_store_return_loss,
    SUM(inv_agg.total_qty)            AS total_inventory_qty,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS store_profit_category,
    (SELECT MAX(i2.i_current_price)
       FROM item i2
      WHERE i2.i_brand = i.i_brand) AS max_brand_price
FROM catalog_sales cs
JOIN date_dim d_sales          ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales          ON cs.cs_sold_time_sk = t_sales.t_time_sk
JOIN item i                    ON cs.cs_item_sk = i.i_item_sk
JOIN household_demographics hd_bill   ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN catalog_returns cr        ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_return         ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return         ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN reason r                  ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_sales ss            ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d_store_sales    ON ss.ss_sold_date_sk = d_store_sales.d_date_sk
JOIN time_dim t_store_sales    ON ss.ss_sold_time_sk = t_store_sales.t_time_sk
JOIN store s                   ON ss.ss_store_sk = s.s_store_sk
JOIN household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
JOIN store_returns sr          ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim d_store_return   ON sr.sr_returned_date_sk = d_store_return.d_date_sk
JOIN time_dim t_store_return   ON sr.sr_return_time_sk = t_store_return.t_time_sk
JOIN reason r2                 ON sr.sr_reason_sk = r2.r_reason_sk
JOIN inventory_agg inv_agg     ON inv_agg.inv_item_sk = i.i_item_sk
JOIN date_dim d_inventory      ON inv_agg.inv_date_sk = d_inventory.d_date_sk
JOIN web_page wp               ON wp.wp_creation_date_sk = d_inventory.d_date_sk
JOIN date_dim d_wp             ON wp.wp_creation_date_sk = d_wp.d_date_sk
JOIN web_site ws               ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_ws             ON ws.web_open_date_sk = d_ws.d_date_sk
WHERE d_sales.d_year = 2000
GROUP BY
    i.i_item_id,
    i.i_product_name,
    d_sales.d_year,
    s.s_store_name,
    r.r_reason_desc,
    i.i_brand
ORDER BY total_catalog_sales DESC
LIMIT 100
