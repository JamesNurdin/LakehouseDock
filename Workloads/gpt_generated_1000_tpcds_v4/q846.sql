WITH sales_returns AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_hdemo_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        td.t_hour,
        SUM(COALESCE(sr.sr_refunded_cash, 0)) AS total_refunded_cash,
        SUM(COALESCE(sr.sr_store_credit, 0)) AS total_store_credit,
        COUNT(sr.sr_ticket_number) AS return_cnt
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_return_time_sk = td.t_time_sk
    WHERE ss.ss_wholesale_cost > 30
      AND ss.ss_ext_tax BETWEEN 1 AND 20
      AND td.t_hour >= 8
      AND hd.hd_vehicle_count >= 1
    GROUP BY
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_hdemo_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        td.t_hour
)
SELECT
    srh.profit_flag,
    AVG(srh.total_sales) AS avg_total_sales,
    SUM(srh.total_refunded_cash) AS sum_refunded_cash,
    COUNT(*) AS num_tickets
FROM (
    SELECT
        ss_ticket_number,
        ss_ext_sales_price AS total_sales,
        ss_net_profit,
        total_refunded_cash,
        total_store_credit,
        CASE WHEN ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM sales_returns
    WHERE total_refunded_cash > 100
      AND EXISTS (
          SELECT 1 FROM store_returns r
          WHERE r.sr_ticket_number = sales_returns.ss_ticket_number
            AND r.sr_store_credit > 0
      )
) srh
GROUP BY srh.profit_flag
HAVING COUNT(*) >= 5
ORDER BY avg_total_sales DESC
LIMIT 100
