WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
sales_data AS (
    SELECT
        cc.cc_name,
        i.i_brand,
        ib.ib_lower_bound,
        CASE WHEN i.i_current_price > 200 THEN 'Premium' ELSE 'Standard' END AS price_category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUM(inv_agg.total_qty_on_hand) AS total_inventory_qty
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
    JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    JOIN customer_address ca_wr ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
    JOIN customer c_wr ON wr.wr_refunded_customer_sk = c_wr.c_customer_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_brand = 'Brand#45'
      AND ib.ib_lower_bound >= 50000
      AND ws.ws_quantity >= 2
    GROUP BY cc.cc_name,
             i.i_brand,
             ib.ib_lower_bound,
             CASE WHEN i.i_current_price > 200 THEN 'Premium' ELSE 'Standard' END
)
SELECT
    cc_name,
    i_brand,
    ib_lower_bound,
    price_category,
    total_sales,
    total_discount,
    total_profit,
    total_catalog_return_amount,
    total_web_return_amount,
    distinct_orders,
    total_inventory_qty,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_sales DESC) AS sales_rank
FROM sales_data
ORDER BY total_sales DESC
LIMIT 100
