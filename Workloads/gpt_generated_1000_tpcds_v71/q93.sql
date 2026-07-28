WITH sales_returns AS (
    SELECT
        s.s_store_id AS store_id,
        d_sales.d_date AS sales_date,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        COUNT(DISTINCT wr.wr_order_number) AS return_transactions
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr ON ss.ss_sold_date_sk = wr.wr_returned_date_sk
        AND ss.ss_sold_time_sk = wr.wr_returned_time_sk
        AND ss.ss_item_sk = wr.wr_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN inventory i ON i.inv_date_sk = d_sales.d_date_sk
    LEFT JOIN call_center cc ON cc.cc_open_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_returns ON wr.wr_returned_date_sk = d_returns.d_date_sk
    WHERE d_sales.d_year = 2001
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND t.t_sub_shift = 'morning'
      AND i.inv_quantity_on_hand > 0
    GROUP BY s.s_store_id, d_sales.d_date
)
SELECT
    store_id,
    AVG(total_sales_profit - total_return_loss) AS avg_daily_net,
    SUM(sales_transactions) AS total_sales_tx,
    SUM(return_transactions) AS total_return_tx
FROM sales_returns
WHERE total_sales_profit > 1000
GROUP BY store_id
HAVING SUM(total_sales_profit) > 5000
ORDER BY avg_daily_net DESC
LIMIT 100
