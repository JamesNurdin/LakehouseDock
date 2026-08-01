WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_coupon_amt,
        cs.cs_ext_tax,
        d_sold.d_year,
        i.i_category,
        i.i_brand,
        w.w_suite_number,
        hd_bill.hd_income_band_sk
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    -- inventory linked through item, warehouse and the same sold date
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
       AND inv.inv_date_sk = d_sold.d_date_sk
    -- web sales linked through item and warehouse
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    -- web returns linked through order number and item
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_category = 'Women'
      AND w.w_suite_number = 'Suite Q'
      AND hd_bill.hd_income_band_sk IN (10, 18)
      AND cs.cs_coupon_amt > 1000
      AND cs.cs_ext_tax < 100
)
SELECT
    base.i_category,
    base.d_year,
    SUM(base.cs_net_paid) AS total_net_paid,
    AVG(base.cs_coupon_amt) AS avg_coupon_amt,
    SUM(base.cs_quantity) AS total_quantity,
    COUNT(DISTINCT base.cs_order_number) AS order_cnt,
    (SELECT SUM(wr2.wr_net_loss)
       FROM web_returns wr2
       JOIN date_dim d_ret ON wr2.wr_returned_date_sk = d_ret.d_date_sk
       JOIN item i_ret ON wr2.wr_item_sk = i_ret.i_item_sk
      WHERE d_ret.d_year = base.d_year
        AND i_ret.i_category = base.i_category) AS total_return_loss
FROM base
GROUP BY base.i_category, base.d_year
ORDER BY total_net_paid DESC
LIMIT 100
