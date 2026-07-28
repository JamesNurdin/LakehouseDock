WITH store_agg AS (
    SELECT sr_customer_sk,
           SUM(sr_return_amt) AS total_store_return,
           COUNT(*) AS cnt_store_returns
    FROM store_returns
    WHERE sr_return_amt > 50
      AND sr_reversed_charge < 500
    GROUP BY sr_customer_sk
),
web_agg AS (
    SELECT wr_refunded_customer_sk AS customer_sk,
           SUM(wr_return_amt) AS total_web_return,
           COUNT(*) AS cnt_web_returns
    FROM web_returns
    WHERE wr_return_amt > 30
    GROUP BY wr_refunded_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ca.ca_state,
    sa.total_store_return,
    wa.total_web_return,
    (sa.total_store_return + wa.total_web_return) AS total_return_amount,
    MAX(wp.wp_url) AS representative_url
FROM store_agg sa
JOIN customer c ON sa.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_agg wa ON wa.customer_sk = c.c_customer_sk
LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk AND wp.wp_type = 'product'
WHERE c.c_birth_year = 1975
  AND c.c_preferred_cust_flag = 'Y'
  AND ca.ca_state IN ('TX', 'CA', 'NY')
  AND cd.cd_education_status = 'College'
  AND EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_link_count > 10
      )
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ca.ca_state,
    sa.total_store_return,
    wa.total_web_return
HAVING (sa.total_store_return + wa.total_web_return) > 200
ORDER BY total_return_amount DESC
LIMIT 100
