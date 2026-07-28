WITH sales_base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        ss.ss_sold_time_sk,
        s.s_store_name,
        s.s_state,
        ca.ca_city AS cust_city,
        ca.ca_gmt_offset,
        hd.hd_buy_potential,
        t.t_hour
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
)
SELECT
    sb.s_store_name,
    sb.s_state,
    sb.cust_city,
    sb.t_hour,
    sb.hd_buy_potential,
    COUNT(DISTINCT sb.ss_ticket_number) AS num_transactions,
    SUM(sb.ss_quantity) AS total_quantity,
    SUM(sb.ss_net_paid_inc_tax) AS total_sales_inc_tax,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_returns_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_returns_loss,
    AVG(sb.ss_net_profit) AS avg_net_profit
FROM sales_base sb
JOIN store_returns sr
    ON sr.sr_ticket_number = sb.ss_ticket_number
   AND sr.sr_item_sk = sb.ss_item_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = sb.ss_sold_time_sk
   AND wr.wr_refunded_hdemo_sk = sb.ss_hdemo_sk
WHERE sb.cust_city = 'Oakland'
  AND sb.ca_gmt_offset = -5.00
  AND sb.t_hour BETWEEN 9 AND 17
  AND sb.ss_net_paid_inc_tax > 1000
GROUP BY
    sb.s_store_name,
    sb.s_state,
    sb.cust_city,
    sb.t_hour,
    sb.hd_buy_potential
ORDER BY total_sales_inc_tax DESC
LIMIT 100
