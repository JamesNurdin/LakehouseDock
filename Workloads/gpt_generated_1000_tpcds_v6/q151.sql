WITH base AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_category AS category,
        d_sold.d_year AS year,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_qty,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_sign
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
    WHERE cd.cd_gender = 'F'
      AND t_sold.t_am_pm = 'PM'
      AND cp.cp_type = 'WEB'
      AND wp.wp_type = 'HOME'
      AND d_sold.d_year BETWEEN 2001 AND 2002
      AND sr.sr_store_sk = 988
    GROUP BY ROLLUP (s.s_store_name, i.i_category, d_sold.d_year)
)
SELECT
    store_name,
    category,
    year,
    total_profit,
    profit_sign,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_profit DESC) AS rank_in_category,
    SUM(total_profit) OVER (PARTITION BY category) AS category_total_profit
FROM base
ORDER BY total_profit DESC
LIMIT 100
