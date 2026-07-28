WITH distinct_promo AS (
    SELECT DISTINCT p_promo_sk, p_promo_name, p_channel_email
    FROM promotion
    WHERE p_channel_email = 'N'
      AND p_item_sk IN (234655, 104599)
),
sales_agg AS (
    SELECT
        dp.p_promo_name,
        dp.p_channel_email,
        td.t_hour,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        MIN(ws.ws_sold_date_sk) AS first_sold_date_sk
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN distinct_promo dp
        ON ws.ws_promo_sk = dp.p_promo_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'S'
      AND cd.cd_dep_employed_count >= 2
      AND td.t_hour = 13
    GROUP BY
        dp.p_promo_name,
        dp.p_channel_email,
        td.t_hour,
        cd.cd_marital_status
)
SELECT
    p_promo_name,
    p_channel_email,
    t_hour,
    cd_marital_status,
    total_net_paid,
    avg_discount,
    distinct_orders,
    first_sold_date_sk,
    RANK() OVER (ORDER BY total_net_paid DESC) AS sales_rank
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
