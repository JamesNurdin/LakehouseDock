WITH joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_quantity,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        hd.hd_income_band_sk,
        ca.ca_state,
        i.i_item_id,
        i.i_product_name,
        i.i_size,
        i.i_color,
        p.p_promo_id,
        p.p_discount_active,
        cp.cp_department,
        inv.inv_quantity_on_hand,
        sr.sr_return_quantity,
        sr.sr_net_loss
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    WHERE
        i.i_size IN ('large', 'medium', 'extra large')
        AND p.p_discount_active = 'Y'
        AND c.c_preferred_cust_flag = 'Y'
        AND ss.ss_net_paid > 1000
        AND inv.inv_quantity_on_hand > 0
        AND cp.cp_department = 'Electronics'
)
SELECT
    jd.c_customer_id,
    jd.c_first_name,
    jd.c_last_name,
    jd.i_item_id,
    jd.i_product_name,
    jd.cp_department,
    jd.ss_net_paid,
    SUM(jd.ss_net_paid) OVER (
        PARTITION BY jd.cp_department
        ORDER BY jd.ss_net_paid DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_dept_net_paid,
    RANK() OVER (
        PARTITION BY jd.cp_department
        ORDER BY jd.ss_net_paid DESC
    ) AS dept_sales_rank,
    CASE
        WHEN jd.sr_net_loss > 0 THEN 'Return'
        ELSE 'Sale'
    END AS transaction_type
FROM joined_data jd
ORDER BY jd.cp_department, dept_sales_rank
LIMIT 100
