WITH sales_agg AS (
    SELECT
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_item_sk,
        cs_promo_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_customer_sk,
        cs_ship_customer_sk,
        cs_bill_cdemo_sk,
        cs_ship_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_ship_hdemo_sk,
        cs_bill_addr_sk,
        cs_ship_addr_sk,
        SUM(cs_net_profit)          AS total_net_profit,
        SUM(cs_quantity)            AS total_quantity,
        SUM(cs_ext_sales_price)     AS total_sales_price,
        SUM(cs_ext_discount_amt)    AS total_discount_amt
    FROM tpcds.catalog_sales
    GROUP BY
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_item_sk,
        cs_promo_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_customer_sk,
        cs_ship_customer_sk,
        cs_bill_cdemo_sk,
        cs_ship_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_ship_hdemo_sk,
        cs_bill_addr_sk,
        cs_ship_addr_sk
),

returns_agg AS (
    SELECT
        wr_item_sk,
        wr_reason_sk,
        wr_web_page_sk,
        SUM(wr_return_quantity) AS total_return_qty,
        SUM(wr_return_amt)      AS total_return_amt
    FROM tpcds.web_returns
    GROUP BY
        wr_item_sk,
        wr_reason_sk,
        wr_web_page_sk
)

SELECT
    cc.cc_name                         AS call_center_name,
    cp.cp_type                         AS catalog_page_type,
    p.p_promo_name                     AS promotion_name,
    i_sales.i_category                 AS item_category,
    MIN(ib.ib_lower_bound)             AS income_lower_bound,
    MIN(ib.ib_upper_bound)             AS income_upper_bound,
    SUM(s.total_net_profit)            AS net_profit,
    SUM(s.total_quantity)              AS quantity_sold,
    SUM(s.total_sales_price)           AS sales_price,
    SUM(s.total_discount_amt)          AS discount_amount,
    COALESCE(SUM(r.total_return_qty), 0) AS quantity_returned,
    COALESCE(SUM(r.total_return_amt), 0) AS amount_returned
FROM sales_agg s
JOIN tpcds.call_center cc
    ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.promotion p
    ON s.cs_promo_sk = p.p_promo_sk
JOIN tpcds.item i_sales
    ON s.cs_item_sk = i_sales.i_item_sk
JOIN tpcds.item i_promo
    ON p.p_item_sk = i_promo.i_item_sk -- second use of the ITEM table
JOIN tpcds.ship_mode sm
    ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
    ON s.cs_warehouse_sk = w.w_warehouse_sk
-- Billing customer dimensions
JOIN tpcds.customer c_bill
    ON s.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN tpcds.customer_address ca_bill
    ON s.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_demographics cd_bill
    ON s.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.household_demographics hd_bill
    ON s.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
-- Shipping customer dimensions
JOIN tpcds.customer c_ship
    ON s.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN tpcds.customer_address ca_ship
    ON s.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN tpcds.customer_demographics cd_ship
    ON s.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN tpcds.household_demographics hd_ship
    ON s.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
-- Income band (via household demographics of the billing customer)
LEFT JOIN tpcds.income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
-- Returns side (optional – may be missing for some items)
LEFT JOIN returns_agg r
    ON s.cs_item_sk = r.wr_item_sk
LEFT JOIN tpcds.reason rs
    ON r.wr_reason_sk = rs.r_reason_sk
LEFT JOIN tpcds.web_page wp
    ON r.wr_web_page_sk = wp.wp_web_page_sk
GROUP BY ROLLUP (
    cc.cc_name,
    cp.cp_type,
    p.p_promo_name,
    i_sales.i_category
)
ORDER BY net_profit DESC NULLS LAST
LIMIT 100
