WITH ws_filtered AS (
    SELECT ws_sold_date_sk,
           ws_sold_time_sk,
           ws_ship_date_sk,
           ws_item_sk,
           ws_bill_customer_sk,
           ws_bill_cdemo_sk,
           ws_bill_hdemo_sk,
           ws_bill_addr_sk,
           ws_ship_customer_sk,
           ws_ship_cdemo_sk,
           ws_ship_hdemo_sk,
           ws_ship_addr_sk,
           ws_web_page_sk,
           ws_web_site_sk,
           ws_ship_mode_sk,
           ws_warehouse_sk,
           ws_promo_sk,
           ws_order_number,
           ws_quantity,
           ws_wholesale_cost,
           ws_list_price,
           ws_sales_price,
           ws_ext_discount_amt,
           ws_ext_sales_price,
           ws_ext_wholesale_cost,
           ws_ext_list_price,
           ws_ext_tax,
           ws_coupon_amt,
           ws_ext_ship_cost,
           ws_net_paid,
           ws_net_paid_inc_tax,
           ws_net_paid_inc_ship,
           ws_net_paid_inc_ship_tax,
           ws_net_profit
    FROM web_sales
    WHERE ws_ship_customer_sk IN (10928779, 1492793, 4105565)
      AND ws_ext_list_price > 5000
      AND ws_coupon_amt BETWEEN 0 AND 200
      AND ws_quantity >= 2
      AND ws_net_paid > 0
),
cd_filtered AS (
    SELECT cd_demo_sk,
           cd_gender,
           cd_marital_status,
           cd_education_status,
           cd_purchase_estimate,
           cd_credit_rating,
           cd_dep_count,
           cd_dep_employed_count,
           cd_dep_college_count
    FROM customer_demographics
    WHERE cd_purchase_estimate >= 5000
      AND cd_credit_rating IN ('Low Risk', 'High Risk')
      AND cd_dep_college_count >= 1
      AND cd_gender = 'M'
      AND cd_education_status = 'College'
)
SELECT
    cd_filtered.cd_gender,
    cd_filtered.cd_credit_rating,
    cd_filtered.cd_dep_college_count,
    COUNT(DISTINCT ws_filtered.ws_order_number) AS order_cnt,
    SUM(ws_filtered.ws_net_paid)               AS total_net_paid,
    AVG(ws_filtered.ws_ext_discount_amt)       AS avg_discount,
    MIN(ws_filtered.ws_ext_list_price)         AS min_list_price,
    MAX(ws_filtered.ws_ext_list_price)         AS max_list_price
FROM ws_filtered
JOIN customer_demographics cd_filtered
  ON ws_filtered.ws_bill_cdemo_sk = cd_filtered.cd_demo_sk
GROUP BY
    cd_filtered.cd_gender,
    cd_filtered.cd_credit_rating,
    cd_filtered.cd_dep_college_count
ORDER BY total_net_paid DESC
LIMIT 100
