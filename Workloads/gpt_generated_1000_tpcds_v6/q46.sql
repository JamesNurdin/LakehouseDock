WITH combined AS (
    SELECT
        s.s_store_sk AS store_sk,
        s.s_store_name AS store_name,
        d_sold.d_year AS year,
        ws.ws_net_profit AS net_profit,
        sr.sr_net_loss AS net_loss,
        w.w_warehouse_name AS warehouse_name,
        wp.wp_url AS web_page_url,
        cd.cd_credit_rating,
        t_sold.t_hour,
        r.r_reason_desc
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
    LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d_sold.d_year = 2001
      AND d_ret.d_year = 2001
      AND cd.cd_credit_rating = 'Good'
      AND s.s_state = 'CA'
      AND w.w_gmt_offset BETWEEN -5 AND 5
      AND t_sold.t_hour BETWEEN 9 AND 17
      AND r.r_reason_desc LIKE '%defect%'
)
SELECT
    store_sk,
    store_name,
    year,
    SUM(net_profit) AS total_net_profit,
    SUM(net_loss) AS total_net_loss,
    COUNT(*) AS txn_count,
    RANK() OVER (PARTITION BY year ORDER BY SUM(net_profit) DESC) AS profit_rank,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = combined.year
    ) AS avg_yearly_profit
FROM combined
GROUP BY store_sk, store_name, year
HAVING SUM(net_profit) > 1000
ORDER BY profit_rank
LIMIT 100
