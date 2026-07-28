WITH joined_data AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        i.i_brand,
        cd.cd_gender,
        td.t_hour,
        web.web_state,
        ss.ss_net_profit,
        ws.ws_net_profit,
        sr.sr_return_amt,
        ws.ws_coupon_amt,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1990
      AND i.i_current_price > 20.00
      AND i.i_brand IN ('Brand#12', 'Brand#23')
      AND cd.cd_gender = 'M'
      AND td.t_hour BETWEEN 9 AND 17
      AND sr.sr_reason_sk IN (21, 38)
      AND ws.ws_coupon_amt > 100.00
),
agg_sales AS (
    SELECT
        c_customer_sk,
        c_birth_year,
        i_brand,
        cd_gender,
        t_hour,
        web_state,
        SUM(ss_net_profit) AS store_profit,
        SUM(ws_net_profit) AS web_profit,
        SUM(sr_return_amt) AS total_returns,
        COUNT(DISTINCT ss_ticket_number) AS store_sales_cnt,
        AVG(ws_coupon_amt) AS avg_coupon_amt
    FROM joined_data
    GROUP BY
        c_customer_sk,
        c_birth_year,
        i_brand,
        cd_gender,
        t_hour,
        web_state
)
SELECT
    c_customer_sk,
    c_birth_year,
    i_brand,
    cd_gender,
    t_hour,
    web_state,
    store_profit,
    web_profit,
    total_returns,
    store_profit + web_profit - total_returns AS total_profit,
    store_sales_cnt,
    avg_coupon_amt
FROM agg_sales
WHERE (store_profit + web_profit - total_returns) > 5000
  AND store_sales_cnt > 2
ORDER BY total_profit DESC
LIMIT 100
