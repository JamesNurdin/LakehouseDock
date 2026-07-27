WITH base AS (
    SELECT
        t_ws.t_hour AS hour_of_day,
        cd_bill.cd_gender AS gender,
        ib.ib_upper_bound AS income_upper,
        SUM(ws.ws_net_paid) AS web_sales_net,
        SUM(ss.ss_net_paid) AS store_sales_net,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets
    FROM web_sales ws
    JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = t_ws.t_time_sk
    JOIN customer_demographics cd_store
        ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
    JOIN household_demographics hd_store
        ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
    JOIN income_band ib2
        ON hd_store.hd_income_band_sk = ib2.ib_income_band_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND cd_bill.cd_gender = 'M'
      AND ib.ib_upper_bound >= 100000
    GROUP BY t_ws.t_hour, cd_bill.cd_gender, ib.ib_upper_bound
    HAVING (SUM(ws.ws_net_paid) + SUM(ss.ss_net_paid)) > 10000
)
SELECT
    hour_of_day,
    gender,
    income_upper,
    web_sales_net,
    store_sales_net,
    (web_sales_net + store_sales_net) AS total_net,
    web_orders,
    store_tickets,
    ROW_NUMBER() OVER (PARTITION BY gender ORDER BY (web_sales_net + store_sales_net) DESC) AS gender_rank
FROM base
WHERE (web_sales_net + store_sales_net) > 5000
ORDER BY total_net DESC
LIMIT 100
