SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    st.s_state,
    st.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    wp.wp_type,
    COUNT(*) AS order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_ext_tax) AS total_tax,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_net_paid) *
        CASE
            WHEN cd.cd_credit_rating = 'Excellent' THEN 1.2
            WHEN cd.cd_credit_rating = 'Good'      THEN 1.0
            ELSE 0.8
        END AS adjusted_net_paid,
    CASE
        WHEN cd.cd_dep_count > 3               THEN 'Large'
        WHEN cd.cd_dep_count BETWEEN 1 AND 3   THEN 'Medium'
        ELSE 'Small'
    END AS dep_size
FROM web_sales ws
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_page_create
    ON wp.wp_creation_date_sk = d_page_create.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
JOIN store st
    ON st.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
  AND wp.wp_type IS NOT NULL
GROUP BY ROLLUP (
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    st.s_state,
    st.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    wp.wp_type,
    cd.cd_dep_count
)
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
