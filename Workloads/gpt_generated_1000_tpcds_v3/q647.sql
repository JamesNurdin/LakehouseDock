WITH aggregated AS (
    SELECT
        s.s_store_name,
        i.i_category,
        d_date.d_year,
        d_date.d_month_seq,
        ca_sr.ca_state,
        SUM(sr.sr_return_amt) AS sum_store_return_amt,
        SUM(wr.wr_return_amt) AS sum_web_return_amt,
        SUM(sr.sr_net_loss + wr.wr_net_loss) AS sum_total_net_loss,
        AVG(sr.sr_return_amt) AS avg_store_return_amt,
        AVG(wr.wr_return_amt) AS avg_web_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS cnt_store_returns,
        COUNT(DISTINCT wr.wr_order_number) AS cnt_web_returns,
        MAX(sr.sr_net_loss) AS max_store_net_loss,
        MIN(wr.wr_net_loss) AS min_web_net_loss,
        CASE WHEN SUM(sr.sr_net_loss + wr.wr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_date
        ON sr.sr_returned_date_sk = d_date.d_date_sk
    JOIN time_dim t_time
        ON sr.sr_return_time_sk = t_time.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d_date.d_date_sk
        AND wr.wr_returned_time_sk = t_time.t_time_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN household_demographics hd_wr_refunded
        ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    JOIN household_demographics hd_wr_returning
        ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    JOIN customer_address ca_wr_refunded
        ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    JOIN customer_address ca_wr_returning
        ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    WHERE d_date.d_year = 2000
      AND d_date.d_month_seq = 12
      AND i.i_category = 'Electronics'
      AND i.i_current_price > 100
      AND ca_sr.ca_state = 'CA'
      AND s.s_store_id = 'S001'
      AND t_time.t_hour BETWEEN 9 AND 17
      AND wp.wp_max_ad_count >= 2
    GROUP BY
        s.s_store_name,
        i.i_category,
        d_date.d_year,
        d_date.d_month_seq,
        ca_sr.ca_state
)
SELECT
    a.s_store_name,
    a.i_category,
    a.d_year,
    a.d_month_seq,
    a.ca_state,
    a.sum_store_return_amt,
    a.sum_web_return_amt,
    a.avg_store_return_amt,
    a.avg_web_return_amt,
    a.cnt_store_returns,
    a.cnt_web_returns,
    a.max_store_net_loss,
    a.min_web_net_loss,
    a.loss_category,
    SUM(a.sum_store_return_amt + a.sum_web_return_amt) OVER (
        PARTITION BY a.s_store_name
        ORDER BY a.d_year, a.d_month_seq
        ROWS UNBOUNDED PRECEDING
    ) AS running_total_return_amt
FROM aggregated a
ORDER BY a.s_store_name, a.d_year, a.d_month_seq
LIMIT 100
