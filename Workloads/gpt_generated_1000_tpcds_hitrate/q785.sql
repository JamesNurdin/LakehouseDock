WITH customer_returns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS cust_total_return,
        COUNT(DISTINCT sr.sr_ticket_number) AS cust_distinct_tickets
    FROM tpcds.store_returns sr
    GROUP BY sr.sr_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_salutation,
    d.d_year,
    i.i_item_id,
    i.i_product_name,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    cr.cust_total_return,
    cr.cust_distinct_tickets,
    COUNT(DISTINCT i.i_item_id) OVER (PARTITION BY c.c_customer_sk) AS distinct_items_per_customer,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date DESC) AS rn_return_desc,
    RANK() OVER (PARTITION BY d.d_year ORDER BY cr.cust_total_return DESC) AS yearly_customer_return_rank,
    CASE 
        WHEN ib.ib_upper_bound > 120000 THEN 'High Income'
        ELSE 'Mid/Low Income'
    END AS income_category,
    (
        SELECT SUM(p2.p_cost)
        FROM tpcds.promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
    ) AS total_promo_cost_for_item
FROM tpcds.store_returns sr
JOIN tpcds.date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN tpcds.item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN tpcds.customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN tpcds.web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN tpcds.date_dim d_wp
    ON wp.wp_creation_date_sk = d_wp.d_date_sk
JOIN customer_returns cr
    ON cr.sr_customer_sk = sr.sr_customer_sk
WHERE
    d.d_year = 2001
    AND i.i_current_price BETWEEN 10 AND 100
    AND cd.cd_gender = 'M'
    AND hd.hd_buy_potential = '5001-10000'
    AND ib.ib_upper_bound <= 150000
    AND sr.sr_return_quantity > 1
    AND c.c_salutation = 'Mr.'
ORDER BY
    cr.cust_total_return DESC,
    rn_return_desc
LIMIT 100
