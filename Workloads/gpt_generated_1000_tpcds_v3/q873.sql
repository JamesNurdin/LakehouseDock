WITH base AS (
    SELECT
        s.s_store_name,
        s.s_state,
        t.t_hour,
        r.r_reason_desc,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        ss.ss_coupon_amt,
        ss.ss_net_profit,
        ss.ss_customer_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_net_loss
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE s.s_street_name = 'Lee'
      AND ss.ss_coupon_amt > 100.00
      AND ss.ss_wholesale_cost BETWEEN 30 AND 70
      AND wp.wp_rec_start_date >= DATE '1999-01-01'
      AND t.t_hour = 10
)
SELECT
    s_store_name,
    s_state,
    t_hour,
    r_reason_desc,
    SUM(ss_ext_sales_price) AS total_sales_price,
    SUM(ss_quantity) AS total_quantity,
    AVG(ss_coupon_amt) AS avg_coupon_amt,
    SUM(wr_return_amt) AS total_return_amount,
    SUM(wr_return_quantity) AS total_return_quantity,
    SUM(ss_net_profit) - SUM(wr_net_loss) AS net_profit,
    COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
    MAX(wr_return_amt) AS max_return_amt,
    MIN(ss_ext_sales_price) AS min_sales_price,
    SUM(ss_net_profit) / (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS profit_vs_avg
FROM base
GROUP BY s_store_name, s_state, t_hour, r_reason_desc
HAVING SUM(ss_net_profit) > (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2)
ORDER BY net_profit DESC
LIMIT 100
