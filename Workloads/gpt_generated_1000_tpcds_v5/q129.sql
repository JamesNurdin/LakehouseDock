WITH ss_agg AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        COUNT(*) AS store_sales_cnt,
        SUM(ss_net_paid_inc_tax) AS store_sales_net,
        AVG(ss_list_price) AS store_sales_avg_price
    FROM store_sales
    WHERE ss_list_price > 20.00
      AND ss_quantity BETWEEN 1 AND 5
    GROUP BY ss_sold_date_sk
    HAVING SUM(ss_net_paid_inc_tax) > 1000
)
SELECT
    d.d_year,
    d.d_month_seq,
    d.d_week_seq,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_store_tickets,
    SUM(ss.ss_net_paid_inc_tax) AS total_store_net,
    AVG(ws.ws_net_profit) AS avg_web_profit,
    SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
    COUNT(DISTINCT ws.ws_order_number) AS num_web_orders
FROM date_dim d
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN web_sales ws ON ws.ws_ship_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_qoy = 2
  AND d.d_week_seq IN (7, 17, 5)
  AND d.d_current_year = 'Y'
  AND ss.ss_list_price BETWEEN 30 AND 200
  AND ws.ws_ship_hdemo_sk = 5848
  AND EXISTS (
        SELECT 1 FROM ss_agg a
        WHERE a.date_sk = d.d_date_sk
          AND a.store_sales_cnt > 10
    )
GROUP BY d.d_year, d.d_month_seq, d.d_week_seq
HAVING SUM(ws.ws_net_paid_inc_tax) > 5000
ORDER BY total_store_net DESC
LIMIT 100
