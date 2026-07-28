WITH store_metrics AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        t.t_hour,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
        SUM(sr.sr_net_loss) AS store_return_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
        SUM(cr.cr_net_loss) AS catalog_return_net_loss,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_cnt,
        SUM(ws.ws_net_profit) AS web_sales_profit
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE t.t_hour BETWEEN 8 AND 17
      AND hd.hd_dep_count >= 4
      AND s.s_state = 'CA'
      AND ws.ws_ext_list_price > 5000
    GROUP BY s.s_store_id, s.s_store_name, t.t_hour
    HAVING SUM(sr.sr_net_loss) > 0
)
SELECT
    s_store_id,
    s_store_name,
    t_hour,
    store_return_cnt,
    catalog_return_cnt,
    web_sales_cnt,
    store_return_net_loss,
    catalog_return_net_loss,
    web_sales_profit,
    RANK() OVER (ORDER BY store_return_net_loss DESC) AS loss_rank,
    DENSE_RANK() OVER (PARTITION BY t_hour ORDER BY web_sales_profit DESC) AS profit_rank_by_hour,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY t_hour) AS hr_seq
FROM store_metrics
ORDER BY loss_rank
LIMIT 100
