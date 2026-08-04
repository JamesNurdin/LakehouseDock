WITH filtered_returns AS (
    SELECT sr_returned_date_sk,
           sr_return_time_sk,
           sr_item_sk,
           sr_customer_sk,
           sr_cdemo_sk,
           sr_hdemo_sk,
           sr_addr_sk,
           sr_store_sk,
           sr_reason_sk,
           sr_ticket_number,
           sr_return_quantity,
           sr_return_amt,
           sr_return_tax,
           sr_return_amt_inc_tax,
           sr_fee,
           sr_return_ship_cost,
           sr_refunded_cash,
           sr_reversed_charge,
           sr_store_credit,
           sr_net_loss
    FROM store_returns
    WHERE sr_reason_sk IN (6, 9, 17, 23)
      AND sr_return_amt > 200
      AND sr_return_quantity >= 1
      AND sr_returned_date_sk BETWEEN 2450000 AND 2455000
),
filtered_customer AS (
    SELECT c_customer_sk,
           c_customer_id,
           c_current_cdemo_sk,
           c_current_hdemo_sk,
           c_current_addr_sk,
           c_first_shipto_date_sk,
           c_first_sales_date_sk,
           c_salutation,
           c_first_name,
           c_last_name,
           c_preferred_cust_flag,
           c_birth_day,
           c_birth_month,
           c_birth_year,
           c_birth_country,
           c_login,
           c_email_address,
           c_last_review_date
    FROM customer
    WHERE c_salutation = 'Mrs.'
      AND c_birth_year = 1985
      AND c_first_sales_date_sk >= 2450500
      AND c_preferred_cust_flag = 'Y'
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT cu.c_customer_id) AS distinct_customers,
    SUM(fr.sr_return_amt) AS total_return_amount,
    AVG(fr.sr_return_amt) AS avg_return_amount,
    MIN(fr.sr_return_amt) AS min_return_amount,
    MAX(fr.sr_return_amt) AS max_return_amount
FROM filtered_returns fr
JOIN filtered_customer cu
    ON fr.sr_customer_sk = cu.c_customer_sk
JOIN customer_demographics cd
    ON fr.sr_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_purchase_estimate >= 3000
  AND cd.cd_dep_count <= 2
GROUP BY cd.cd_gender, cd.cd_marital_status
HAVING SUM(fr.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
