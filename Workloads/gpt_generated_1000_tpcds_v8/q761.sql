WITH
    sampled_sales AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    demog_bill AS (
        SELECT cd_demo_sk, cd_gender, cd_purchase_estimate
        FROM customer_demographics
    ),
    demog_ship AS (
        SELECT cd_demo_sk, cd_gender AS ship_gender, cd_purchase_estimate AS ship_purchase_estimate
        FROM customer_demographics
    ),
    hh_bill AS (
        SELECT hd_demo_sk, hd_income_band_sk, hd_buy_potential
        FROM household_demographics
    ),
    hh_ship AS (
        SELECT hd_demo_sk, hd_income_band_sk AS ship_income_band_sk, hd_buy_potential AS ship_buy_potential
        FROM household_demographics
    ),
    ca_bill AS (
        SELECT ca_address_sk, ca_city, ca_state
        FROM customer_address
    ),
    ca_ship AS (
        SELECT ca_address_sk, ca_city AS ship_city, ca_state AS ship_state
        FROM customer_address
    ),
    page AS (
        SELECT wp_web_page_sk, wp_url, wp_type, wp_autogen_flag, wp_rec_start_date
        FROM web_page
        WHERE wp_autogen_flag = 'Y'
    ),
    high_value_orders AS (
        SELECT ws_order_number
        FROM sampled_sales
        WHERE ws_net_paid_inc_tax > 2000
    ),
    large_quantity_orders AS (
        SELECT ws_order_number
        FROM sampled_sales
        WHERE ws_quantity > 10
    ),
    valid_orders AS (
        SELECT ws_order_number
        FROM high_value_orders
        INTERSECT
        SELECT ws_order_number
        FROM large_quantity_orders
    )
SELECT
    cb.ca_city AS bill_city,
    cs.ship_city AS ship_city,
    db.cd_gender AS bill_gender,
    ds.ship_gender AS ship_gender,
    SUM(ss.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ws_order_number) AS order_cnt,
    RANK() OVER (ORDER BY SUM(ss.ws_ext_sales_price) DESC) AS sales_rank,
    (SELECT AVG(cd_purchase_estimate) FROM demog_bill) AS avg_bill_purchase_est,
    CASE WHEN EXISTS (
        SELECT 1 FROM page wp2 WHERE wp2.wp_type = p.wp_type
    ) THEN 'Y' ELSE 'N' END AS has_same_type_page,
    qty
FROM sampled_sales ss
JOIN demog_bill db        ON ss.ws_bill_cdemo_sk = db.cd_demo_sk
JOIN demog_ship ds        ON ss.ws_ship_cdemo_sk = ds.cd_demo_sk
JOIN hh_bill hb          ON ss.ws_bill_hdemo_sk = hb.hd_demo_sk
JOIN hh_ship hs          ON ss.ws_ship_hdemo_sk = hs.hd_demo_sk
JOIN ca_bill cb          ON ss.ws_bill_addr_sk = cb.ca_address_sk
JOIN ca_ship cs          ON ss.ws_ship_addr_sk = cs.ca_address_sk
JOIN page p              ON ss.ws_web_page_sk = p.wp_web_page_sk
JOIN page p_dup          ON ss.ws_web_page_sk = p_dup.wp_web_page_sk   -- second join to web_page under a different alias
JOIN valid_orders vo    ON ss.ws_order_number = vo.ws_order_number
CROSS JOIN UNNEST(ARRAY[ss.ws_quantity, ss.ws_quantity * 2]) AS t(qty)
WHERE EXISTS (
    SELECT 1
    FROM customer_address ca_chk
    WHERE ca_chk.ca_state = cb.ca_state
      AND ca_chk.ca_city = cb.ca_city
)
GROUP BY
    cb.ca_city,
    cs.ship_city,
    db.cd_gender,
    ds.ship_gender,
    p.wp_type,
    qty
ORDER BY total_sales DESC
LIMIT 100
