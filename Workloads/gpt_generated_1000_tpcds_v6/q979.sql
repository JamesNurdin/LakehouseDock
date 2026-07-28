WITH joined_data AS (
    SELECT
        s.s_state,
        cd.cd_marital_status,
        r.r_reason_desc,
        c.c_customer_sk,
        i.i_current_price,
        sr.sr_return_amt,
        cr.cr_return_amount
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON i.i_item_sk = cs.cs_item_sk
    JOIN promotion p
        ON p.p_promo_sk = cs.cs_promo_sk
    JOIN customer c
        ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN customer_demographics cd
        ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN customer_address ca
        ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_store_sk = sr.sr_store_sk
    JOIN reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    JOIN time_dim t
        ON t.t_time_sk = sr.sr_return_time_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE r.r_reason_desc = 'Found a better price in a store'
      AND cd.cd_marital_status = 'S'
      AND cd.cd_dep_college_count >= 1
      AND p.p_response_target = 1
      AND ib.ib_upper_bound >= 50000
      AND i.i_current_price > 100
      AND t.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
)
SELECT
    s_state,
    cd_marital_status,
    r_reason_desc,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(sr_return_amt) AS total_store_return,
    SUM(cr_return_amount) AS total_catalog_return,
    AVG(i_current_price) AS avg_item_price
FROM joined_data
GROUP BY ROLLUP (s_state, cd_marital_status, r_reason_desc)
HAVING SUM(sr_return_amt) > 1000
   AND COUNT(DISTINCT c_customer_sk) >= 5
ORDER BY s_state, cd_marital_status, r_reason_desc
LIMIT 100
