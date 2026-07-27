/*
Goal: Analyze store performance by combining store sales with customer demographics, return reasons and web return costs. The query joins all five tables, applies several realistic filters, aggregates sales and profit metrics, uses a scalar subquery to compare average return amount, adds a ranking window function, filters groups with HAVING, orders by total sales and limits to the top 100 rows.
*/
WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_manager,
        cd.cd_gender,
        r.r_reason_desc,
        SUM(ss.ss_ext_sales_price)        AS total_sales,
        SUM(ss.ss_net_profit)              AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt,
        AVG(ss.ss_quantity)                AS avg_quantity,
        MAX(ss.ss_quantity)                AS max_quantity
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE s.s_manager = 'Robert Thompson'
      AND cd.cd_gender = 'M'
      AND ss.ss_quantity > 5
      AND ss.ss_sales_price > 100.00
      AND (r.r_reason_desc LIKE '%color%' OR r.r_reason_desc LIKE '%warranty%')
    GROUP BY s.s_store_id, s.s_manager, cd.cd_gender, r.r_reason_desc
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    sa.s_store_id,
    sa.s_manager,
    sa.cd_gender,
    sa.r_reason_desc,
    sa.total_sales,
    sa.total_profit,
    sa.ticket_cnt,
    sa.avg_quantity,
    ROW_NUMBER() OVER (ORDER BY sa.total_sales DESC) AS sales_rank,
    (SELECT AVG(wr_return_amt) FROM web_returns WHERE wr_fee > 20.00) AS avg_return_amt_over_fee
FROM sales_agg sa
ORDER BY sa.total_sales DESC
LIMIT 100
