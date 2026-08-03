WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_ext_wholesale_cost,
        ws.ws_ext_sales_price,
        w.w_country,
        w.w_warehouse_id,
        p.p_promo_id,
        p.p_channel_email,
        CASE
            WHEN ws.ws_net_profit > 1000 THEN 'High'
            WHEN ws.ws_net_profit > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site s
        ON ws.ws_web_site_sk = s.web_site_sk
    WHERE ws.ws_quantity > 5
      AND ws.ws_net_profit > 0
      AND w.w_country = 'United States'
      AND ws.ws_order_number IN (
          SELECT ws1.ws_order_number
          FROM web_sales ws1
          EXCEPT
          SELECT ws2.ws_order_number
          FROM web_sales ws2
          JOIN promotion p2
              ON ws2.ws_promo_sk = p2.p_promo_sk
          WHERE p2.p_cost = 0
      )
),
agg_by_country_category AS (
    SELECT
        w_country,
        profit_category,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        AVG(ws_net_profit) AS avg_profit
    FROM filtered_sales
    GROUP BY w_country, profit_category
),
high_medium AS (
    SELECT w_country, profit_category, total_profit
    FROM agg_by_country_category
    WHERE profit_category IN ('High','Medium')
),
low_only AS (
    SELECT w_country, profit_category, total_profit
    FROM agg_by_country_category
    WHERE profit_category = 'Low'
)
SELECT AVG(total_profit) AS avg_total_profit_over_union
FROM (
    SELECT w_country, profit_category, total_profit FROM high_medium
    UNION
    SELECT w_country, profit_category, total_profit FROM low_only
) u
