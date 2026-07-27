WITH sales_detail AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        p.p_promo_id,
        p.p_purpose,
        t.t_hour,
        t.t_am_pm,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_web_site_sk,
        s.web_name,
        s.web_state
    FROM web_sales ws
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site s
      ON ws.ws_web_site_sk = s.web_site_sk
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_hour = 9
      AND t.t_am_pm = 'PM'
      AND p.p_purpose = 'Unknown'
      AND p.p_channel_tv = 'N'
      AND c.c_birth_year BETWEEN 1960 AND 1970
      AND ws.ws_quantity > 5
      AND ws.ws_ext_sales_price > 100
),
agg_sales AS (
    SELECT
        c_customer_id,
        p_promo_id,
        t_hour,
        web_name,
        COUNT(*) AS order_cnt,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_discount_amt) AS avg_discount,
        MIN(ws_net_profit) AS min_profit,
        MAX(ws_net_profit) AS max_profit
    FROM sales_detail
    GROUP BY c_customer_id, p_promo_id, t_hour, web_name
    HAVING SUM(ws_ext_sales_price) > 1000
       AND COUNT(*) > 10
)
SELECT
    c_customer_id,
    p_promo_id,
    t_hour,
    web_name,
    order_cnt,
    total_sales,
    avg_discount,
    min_profit,
    max_profit,
    RANK() OVER (PARTITION BY p_promo_id ORDER BY total_sales DESC) AS promo_sales_rank
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
