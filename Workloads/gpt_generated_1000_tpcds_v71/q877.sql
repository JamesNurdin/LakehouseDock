WITH sales_data AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_quantity AS quantity,
        cc.cc_name AS call_center_name,
        cp.cp_type AS catalog_page_type,
        i.i_brand AS item_brand,
        hd_bill.hd_buy_potential AS buy_potential,
        ib.ib_lower_bound AS income_lower,
        p.p_discount_active AS promo_active
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1980
      AND hd_bill.hd_buy_potential = '5001-10000'
      AND i.i_current_price > 100
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'monthly'
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1 FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 500
      )
),
returns_data AS (
    SELECT
        cr.cr_order_number AS order_number,
        cr.cr_returned_date_sk AS sold_date_sk,
        cr.cr_return_amount AS net_paid,
        cr.cr_return_quantity AS quantity,
        cc.cc_name AS call_center_name,
        cp.cp_type AS catalog_page_type,
        i.i_brand AS item_brand,
        hd_ref.hd_buy_potential AS buy_potential,
        ib.ib_lower_bound AS income_lower,
        p.p_discount_active AS promo_active
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c_ref.c_birth_year BETWEEN 1970 AND 1980
      AND hd_ref.hd_buy_potential = '5001-10000'
      AND i.i_current_price > 100
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'monthly'
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1 FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 500
      )
)
SELECT
    call_center_name,
    catalog_page_type,
    item_brand,
    buy_potential,
    income_lower,
    COUNT(DISTINCT order_number) AS orders,
    SUM(quantity) AS total_quantity,
    SUM(net_paid) AS total_amount,
    AVG(net_paid) AS avg_amount
FROM (
    SELECT
        order_number,
        sold_date_sk,
        net_paid,
        quantity,
        call_center_name,
        catalog_page_type,
        item_brand,
        buy_potential,
        income_lower,
        promo_active
    FROM sales_data
    UNION ALL
    SELECT
        order_number,
        sold_date_sk,
        net_paid,
        quantity,
        call_center_name,
        catalog_page_type,
        item_brand,
        buy_potential,
        income_lower,
        promo_active
    FROM returns_data
) AS combined
GROUP BY
    call_center_name,
    catalog_page_type,
    item_brand,
    buy_potential,
    income_lower
ORDER BY total_amount DESC
LIMIT 100
