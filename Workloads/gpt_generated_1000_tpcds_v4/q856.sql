WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_promo_sk,
        ws.ws_net_paid_inc_ship,
        ws.ws_ext_ship_cost,
        ws.ws_quantity,
        ws.ws_item_sk
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND cd.cd_gender = 'M'
      AND cd.cd_education_status = 'Advanced Degree'
      AND p.p_discount_active = 'Y'
      AND td.t_hour BETWEEN 9 AND 17
      AND ws.ws_net_paid_inc_ship > 500
      AND ws.ws_ext_ship_cost < 1000
)
SELECT
    c.c_customer_id,
    cd.cd_education_status,
    td.t_hour,
    p.p_promo_name,
    COUNT(DISTINCT fs.ws_order_number) AS order_cnt,
    SUM(fs.ws_net_paid_inc_ship) AS total_sales,
    AVG(fs.ws_ext_ship_cost) AS avg_ship_cost,
    MIN(fs.ws_net_paid_inc_ship) AS min_sale,
    MAX(fs.ws_net_paid_inc_ship) AS max_sale
FROM filtered_sales fs
JOIN customer c ON fs.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON fs.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN time_dim td ON fs.ws_sold_time_sk = td.t_time_sk
JOIN promotion p ON fs.ws_promo_sk = p.p_promo_sk
GROUP BY
    c.c_customer_id,
    cd.cd_education_status,
    td.t_hour,
    p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
