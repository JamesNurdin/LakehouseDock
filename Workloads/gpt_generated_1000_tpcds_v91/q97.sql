WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk, inv_date_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d_cs.d_date AS sales_date,
    cust_cs_bill.c_customer_id AS billing_customer,
    CASE WHEN cd_cs_bill.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS billing_customer_gender,
    p_cs.p_promo_name AS promotion_name,
    sm_cs.sm_type AS ship_mode,
    w_cs.w_warehouse_name AS warehouse_name,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    SUM(cs.cs_quantity) AS total_catalog_quantity,
    SUM(ws.ws_quantity) AS total_web_quantity,
    COALESCE(SUM(ia.total_qty_on_hand), 0) AS total_inventory_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    CASE WHEN d_cs.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim) THEN 'Latest' ELSE 'Historical' END AS date_category,
    CASE WHEN SUM(cs.cs_quantity) > (SELECT MAX(inv_quantity_on_hand) FROM inventory) THEN 'Large Quantity' ELSE 'Normal Quantity' END AS quantity_category
FROM
    catalog_sales cs
    INNER JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    INNER JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    INNER JOIN date_dim d_ship_cs ON cs.cs_ship_date_sk = d_ship_cs.d_date_sk
    INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
    INNER JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    INNER JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    INNER JOIN customer cust_cs_bill ON cs.cs_bill_customer_sk = cust_cs_bill.c_customer_sk
    INNER JOIN customer_demographics cd_cs_bill ON cs.cs_bill_cdemo_sk = cd_cs_bill.cd_demo_sk
    INNER JOIN household_demographics hd_cs_bill ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
    INNER JOIN customer cust_cs_ship ON cs.cs_ship_customer_sk = cust_cs_ship.c_customer_sk
    INNER JOIN customer_demographics cd_cs_ship ON cs.cs_ship_cdemo_sk = cd_cs_ship.cd_demo_sk
    INNER JOIN household_demographics hd_cs_ship ON cs.cs_ship_hdemo_sk = hd_cs_ship.hd_demo_sk
    LEFT JOIN inv_agg ia ON ia.inv_item_sk = i.i_item_sk AND ia.inv_warehouse_sk = w_cs.w_warehouse_sk
    LEFT JOIN date_dim d_inv ON ia.inv_date_sk = d_inv.d_date_sk
    INNER JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    INNER JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    INNER JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    INNER JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    INNER JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    INNER JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    INNER JOIN customer cust_ws_bill ON ws.ws_bill_customer_sk = cust_ws_bill.c_customer_sk
    INNER JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    INNER JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    INNER JOIN customer cust_ws_ship ON ws.ws_ship_customer_sk = cust_ws_ship.c_customer_sk
    INNER JOIN customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
    INNER JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN customer cust_wr_refunded ON wr.wr_refunded_customer_sk = cust_wr_refunded.c_customer_sk
    LEFT JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    LEFT JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    LEFT JOIN customer cust_wr_returning ON wr.wr_returning_customer_sk = cust_wr_returning.c_customer_sk
    LEFT JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
    LEFT JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    LEFT JOIN item i_wr ON wr.wr_item_sk = i_wr.i_item_sk
WHERE
    d_cs.d_year = 2001
GROUP BY
    i.i_item_id,
    i.i_product_name,
    d_cs.d_date,
    cust_cs_bill.c_customer_id,
    cd_cs_bill.cd_gender,
    p_cs.p_promo_name,
    sm_cs.sm_type,
    w_cs.w_warehouse_name,
    d_cs.d_date_sk
ORDER BY
    total_catalog_net_profit DESC
LIMIT 100
