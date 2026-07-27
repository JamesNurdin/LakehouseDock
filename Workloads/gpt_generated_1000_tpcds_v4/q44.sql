WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    JOIN date_dim d_inv ON inventory.inv_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_year = 2001
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    ws.ws_order_number,
    d_sold.d_date AS sold_date,
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cr.cr_return_amount,
    wr.wr_net_loss,
    inv_agg.total_quantity_on_hand,
    RANK() OVER (PARTITION BY i.i_item_id ORDER BY ws.ws_net_paid DESC) AS sales_rank,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = ws.ws_item_sk
    ) AS avg_item_profit
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk AND w.w_warehouse_sk = inv_agg.inv_warehouse_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer cust_ref ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
WHERE d_sold.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND cd.cd_marital_status = 'M'
ORDER BY sales_rank, ws.ws_net_paid DESC
LIMIT 100
