WITH joined_sales_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_item_sk,
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        i.i_current_price AS i_current_price,
        i.i_brand AS i_brand,
        i.i_category AS i_category,
        i.i_manufact AS i_manufact,
        p.p_promo_name,
        p.p_discount_active,
        td_sold.t_hour AS sold_hour,
        td_return.t_hour AS return_hour,
        c_bill.c_customer_id AS bill_customer_id,
        c_bill.c_birth_country AS bill_birth_country,
        ca_bill.ca_state AS bill_state,
        cd_bill.cd_gender AS bill_gender,
        hd_bill.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cr.cr_return_quantity,
        cr.cr_return_amount AS cr_return_amount,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_fee,
        r.r_reason_desc,
        c_returning.c_customer_id AS returning_customer_id,
        c_refunded.c_customer_id AS refunded_customer_id,
        ca_returned.ca_state AS returning_state,
        ca_refunded.ca_state AS refunded_state,
        CASE
            WHEN cr.cr_return_amount > 0 AND cs.cs_net_profit < 0 THEN 'Loss'
            WHEN cr.cr_return_amount > 0 AND cs.cs_net_profit >= 0 THEN 'Profit'
            ELSE 'No Return'
        END AS return_category
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td_sold
        ON cs.cs_sold_time_sk = td_sold.t_time_sk
    JOIN time_dim td_return
        ON cr.cr_returned_time_sk = td_return.t_time_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_returned
        ON cr.cr_returning_addr_sk = ca_returned.ca_address_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450845
      AND i.i_brand_id IN (6012006, 2002002)
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = cs.cs_promo_sk
            AND p2.p_discount_active = 'Y'
      )
)
SELECT
    i_item_id,
    i_product_name,
    i_category,
    i_brand,
    bill_birth_country,
    COUNT(*) AS num_transactions,
    SUM(cs_quantity) AS total_quantity,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(i_current_price) AS avg_item_price,
    MIN(ib_lower_bound) AS min_income_lower,
    MAX(ib_upper_bound) AS max_income_upper,
    SUM(CASE WHEN return_category = 'Loss' THEN 1 ELSE 0 END) AS loss_transactions
FROM joined_sales_returns
GROUP BY
    i_item_id,
    i_product_name,
    i_category,
    i_brand,
    bill_birth_country
ORDER BY total_net_paid DESC
LIMIT 100
