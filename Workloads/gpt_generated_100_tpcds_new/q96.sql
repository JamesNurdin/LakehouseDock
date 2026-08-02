WITH return_summaries AS (
    SELECT
        cr_order_number,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        MAX(cr_returned_date_sk) AS max_return_date_sk
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_order_number
),
store_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        SUM(cs.cs_net_profit) AS store_net_profit,
        SUM(rs.total_return_amount) AS store_return_amount,
        COUNT(DISTINCT cs.cs_order_number) AS orders_count
    FROM return_summaries rs
    JOIN catalog_sales cs
        ON rs.cr_order_number = cs.cs_order_number
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2020
      AND cd_bill.cd_gender = 'F'
      AND s.s_number_employees > 200
      AND w.web_company_id IN (1, 2, 3)
      AND s.s_gmt_offset = -5.00
      AND d_sold.d_holiday = 'N'
      AND rs.total_return_amount > (
          SELECT AVG(total_return_amount) FROM return_summaries
      )
    GROUP BY s.s_store_sk, s.s_store_name
)
SELECT
    ss.s_store_name AS store_name,
    ss.store_net_profit,
    ss.store_return_amount,
    ss.orders_count,
    ss.store_net_profit / NULLIF(ss.orders_count, 0) AS avg_profit_per_order
FROM store_sales ss
WHERE ss.store_net_profit > (
    SELECT AVG(store_net_profit) FROM store_sales
)
ORDER BY ss.store_net_profit DESC
LIMIT 100
