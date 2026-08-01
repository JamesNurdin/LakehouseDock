WITH sales_data AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_return_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_return_loss
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p              ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr    ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN inventory i         ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN call_center cc      ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN web_page wp         ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr      ON wr.wr_returned_date_sk = d.d_date_sk
                                 AND wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN web_site ws         ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'CA'
      AND i.inv_quantity_on_hand > 0
    GROUP BY s.s_store_id, s.s_store_name, d.d_year
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    total_sales,
    total_profit,
    store_return_loss,
    web_return_loss,
    (total_profit - store_return_loss - web_return_loss) AS net_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY (total_profit - store_return_loss - web_return_loss) DESC) AS profit_rank
FROM sales_data
ORDER BY d_year, profit_rank
LIMIT 100
