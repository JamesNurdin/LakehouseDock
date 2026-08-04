WITH agg_sales AS (
    SELECT
        ws_bill_customer_sk,
        ws_bill_addr_sk,
        ws_bill_cdemo_sk,
        ws_sold_date_sk,
        SUM(ws_net_paid) AS total_paid,
        AVG(ws_ext_ship_cost) AS avg_ship_cost,
        COUNT(*) AS order_cnt,
        ARRAY_AGG(ws_quantity) AS qty_array
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_net_paid > 500
      AND ws_quantity >= 2
      AND ws_ship_hdemo_sk = 5528
      AND ws_ext_ship_cost < 2000
    GROUP BY ws_bill_customer_sk, ws_bill_addr_sk, ws_bill_cdemo_sk, ws_sold_date_sk
),
filtered_dates AS (
    SELECT d_date_sk, d_year, d_month_seq, d_day_name
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1200 AND 1210
      AND d_day_name = 'Monday'
      AND d_date_sk IN (SELECT ws_sold_date_sk FROM web_sales WHERE ws_net_paid > 1000)
),
key_set_a AS (
    SELECT ws_bill_customer_sk AS cust_sk FROM web_sales WHERE ws_net_paid > 2000
),
key_set_b AS (
    SELECT ws_bill_customer_sk AS cust_sk FROM web_sales WHERE ws_quantity = 1
),
except_keys AS (
    SELECT cust_sk FROM key_set_a
    EXCEPT
    SELECT cust_sk FROM key_set_b
),
intersect_keys AS (
    SELECT cust_sk FROM key_set_a
    INTERSECT
    SELECT cust_sk FROM key_set_b
)
SELECT
    a.ws_bill_customer_sk,
    a.total_paid,
    a.avg_ship_cost,
    a.order_cnt,
    d.d_year,
    d.d_month_seq,
    ca.ca_city,
    cd.cd_gender,
    (SELECT MAX(ws_net_paid) FROM web_sales ws2 WHERE ws2.ws_bill_customer_sk = a.ws_bill_customer_sk) AS max_paid_scalar,
    uq.qty AS quantity_from_array
FROM agg_sales a
JOIN filtered_dates d ON a.ws_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON a.ws_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON a.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN UNNEST(a.qty_array) AS uq(qty) ON true
WHERE a.ws_bill_customer_sk IN (SELECT cust_sk FROM intersect_keys)
  AND a.ws_bill_customer_sk NOT IN (SELECT cust_sk FROM except_keys)
LIMIT 100
