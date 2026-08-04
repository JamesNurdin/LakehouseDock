WITH sampled_store AS (
    SELECT
        ss_sold_date_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_quantity,
        ss_net_paid,
        ss_list_price
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
cd AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        cd_education_status,
        cd_marital_status,
        cd_credit_rating,
        cd_purchase_estimate
    FROM customer_demographics
    WHERE cd_gender = 'F'
      AND cd_dep_count >= 1
),
ws AS (
    SELECT
        ws_bill_cdemo_sk,
        ws_ship_customer_sk,
        ws_web_page_sk,
        ws_net_paid_inc_tax,
        ws_quantity,
        ws_ext_wholesale_cost,
        ws_sold_date_sk
    FROM web_sales
    WHERE ws_net_paid_inc_tax BETWEEN 100 AND 2000
),
wp AS (
    SELECT
        wp_web_page_sk,
        wp_type,
        wp_char_count
    FROM web_page
    WHERE wp_type = 'home'
      AND wp_char_count > 500
)
SELECT
    s.ss_sold_date_sk,
    s.ss_customer_sk,
    s.ss_quantity,
    s.ss_net_paid,
    c.cd_gender,
    c.cd_dep_count,
    w.ws_ship_customer_sk,
    w.ws_net_paid_inc_tax,
    p.wp_type,
    SUM(s.ss_net_paid) OVER (
        PARTITION BY c.cd_gender
        ORDER BY s.ss_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_paid,
    DENSE_RANK() OVER (
        PARTITION BY p.wp_type
        ORDER BY w.ws_net_paid_inc_tax DESC
    ) AS net_paid_rank,
    LAG(s.ss_quantity) OVER (
        PARTITION BY c.cd_gender
        ORDER BY s.ss_sold_date_sk
    ) AS prev_quantity,
    (s.ss_quantity - LAG(s.ss_quantity) OVER (
        PARTITION BY c.cd_gender
        ORDER BY s.ss_sold_date_sk
    )) AS qty_change
FROM sampled_store s
JOIN cd c
  ON s.ss_cdemo_sk = c.cd_demo_sk
JOIN ws w
  ON c.cd_demo_sk = w.ws_bill_cdemo_sk
JOIN wp p
  ON w.ws_web_page_sk = p.wp_web_page_sk
WHERE s.ss_quantity > (SELECT AVG(ss_quantity) FROM store_sales)
  AND s.ss_customer_sk IN (
      SELECT ss_customer_sk FROM sampled_store WHERE ss_list_price > 20
      INTERSECT
      SELECT ws_ship_customer_sk FROM ws WHERE ws_ext_wholesale_cost > 3000
  )
ORDER BY cumulative_net_paid DESC
LIMIT 100
