WITH cr_side AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_returned_date_sk,
        cc.cc_name,
        cp.cp_catalog_number,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        d.d_year,
        d.d_date,
        c.c_birth_month,
        hd.hd_income_band_sk,
        sm.sm_ship_mode_id AS cr_ship_mode_id,
        cc.cc_name AS cr_call_center_name
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN tpcds.customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
),
wr_side AS (
    SELECT
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_returned_date_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_promo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_web_page_sk,
        p.p_promo_id,
        p.p_discount_active,
        sm2.sm_ship_mode_id AS ws_ship_mode_id,
        w2.w_warehouse_name AS ws_warehouse_name,
        d2.d_year AS sale_year,
        d2.d_date AS sale_date,
        c_bill.c_birth_month AS bill_birth_month,
        hd_bill.hd_income_band_sk AS bill_income_band,
        wp.wp_url
    FROM tpcds.web_returns wr
    JOIN tpcds.web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm2
        ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN tpcds.warehouse w2
        ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN tpcds.customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN tpcds.household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.date_dim d2
        ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN tpcds.time_dim t2
        ON ws.ws_sold_time_sk = t2.t_time_sk
)
SELECT
    COALESCE(cr_side.d_year, wr_side.sale_year) AS year,
    COALESCE(cr_side.d_date, wr_side.sale_date) AS date,
    cr_side.cr_call_center_name,
    cr_side.cp_catalog_number,
    cr_side.cr_ship_mode_id,
    cr_side.w_warehouse_name,
    cr_side.cr_return_quantity,
    cr_side.cr_return_amount,
    wr_side.ws_ext_sales_price,
    wr_side.ws_net_profit,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(cr_side.d_year, wr_side.sale_year)
        ORDER BY cr_side.cr_return_amount DESC
    ) AS rn_return_amount,
    SUM(wr_side.ws_net_profit) OVER (
        PARTITION BY COALESCE(cr_side.d_year, wr_side.sale_year)
        ORDER BY COALESCE(wr_side.sale_date, cr_side.d_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_net_profit_ytd
FROM cr_side
FULL OUTER JOIN wr_side
    ON cr_side.cr_returned_date_sk = wr_side.wr_returned_date_sk
WHERE (
        cr_side.d_year = 2001 OR wr_side.sale_year = 2001
    )
  AND (
        cr_side.c_birth_month IN (3, 6, 11) OR wr_side.bill_birth_month IN (3, 6, 11)
    )
  AND cr_side.w_warehouse_name = 'Warehouse 1'
  AND cr_side.cr_ship_mode_id = 'AIR'
  AND cr_side.cr_call_center_name LIKE '%Center%'
ORDER BY rn_return_amount, date
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
