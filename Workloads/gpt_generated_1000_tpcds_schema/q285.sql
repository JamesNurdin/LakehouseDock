WITH ws_sample AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    d_sold.d_year,
    c_bill.c_customer_id,
    SUM(ws.ws_net_profit) AS total_net_profit,
    RANK() OVER (PARTITION BY d_sold.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
    sm.sm_code,
    p.p_promo_name,
    MAX(i.inv_quantity_on_hand) AS max_inventory_on_hand,
    cp.cp_catalog_page_id
FROM ws_sample ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN customer c_refund
    ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
LEFT JOIN customer_demographics cd_refund
    ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
LEFT JOIN household_demographics hd_refund
    ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
LEFT JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_sold.d_date_sk   -- store_returns linked via the same date_dim used for sales
LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
LEFT JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
FULL OUTER JOIN (
        SELECT *
        FROM inventory
    ) i
    ON i.inv_warehouse_sk = w_ws.w_warehouse_sk
FULL OUTER JOIN warehouse w_inv
    ON i.inv_warehouse_sk = w_inv.w_warehouse_sk
WHERE d_sold.d_year = 2001
  AND d_sold.d_moy IN (1, 4, 12)
  AND sm.sm_code = 'AIR'
  AND p.p_channel_email = 'N'
  AND c_bill.c_birth_country = 'United States'
  AND i.inv_quantity_on_hand > 0
GROUP BY
    d_sold.d_year,
    c_bill.c_customer_id,
    sm.sm_code,
    p.p_promo_name,
    cp.cp_catalog_page_id
ORDER BY
    d_sold.d_year,
    profit_rank,
    c_bill.c_customer_id
LIMIT 100
