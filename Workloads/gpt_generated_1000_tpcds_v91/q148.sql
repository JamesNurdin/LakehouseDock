(
    SELECT
        d.d_year AS year,
        s.s_state AS state,
        cd.cd_gender AS gender,
        promo.p_promo_name AS promo_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        AVG(i.inv_quantity_on_hand) AS avg_inventory,
        MIN(ss.ss_net_profit) AS min_profit,
        MAX(ss.ss_net_profit) AS max_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    CROSS JOIN LATERAL (
        SELECT p.p_promo_name, p.p_discount_active
        FROM promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
    ) AS promo
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
      AND t.t_am_pm = 'PM'
      AND wp.wp_autogen_flag = 'Y'
      AND cc.cc_state = 'TX'
      AND i.inv_quantity_on_hand > 0
    GROUP BY d.d_year, s.s_state, cd.cd_gender, promo.p_promo_name
) INTERSECT (
    SELECT
        d.d_year AS year,
        s.s_state AS state,
        cd.cd_gender AS gender,
        promo.p_promo_name AS promo_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        AVG(i.inv_quantity_on_hand) AS avg_inventory,
        MIN(ss.ss_net_profit) AS min_profit,
        MAX(ss.ss_net_profit) AS max_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    CROSS JOIN LATERAL (
        SELECT p.p_promo_name, p.p_discount_active
        FROM promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
    ) AS promo
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year IN (1999, 2000)
      AND t.t_am_pm = 'PM'
      AND wp.wp_autogen_flag IN ('Y', 'N')
      AND cc.cc_state = 'TX'
      AND i.inv_quantity_on_hand > 0
    GROUP BY d.d_year, s.s_state, cd.cd_gender, promo.p_promo_name
)
ORDER BY total_sales DESC
LIMIT 100
