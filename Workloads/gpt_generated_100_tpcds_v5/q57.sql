WITH base AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        d.d_year AS d_year,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_fee) AS avg_fee,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        MIN(wr.wr_return_amt) AS min_return,
        MAX(wr.wr_return_amt) AS max_return,
        CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS return_level
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE cd_refunded.cd_gender = 'M'
      AND cd_refunded.cd_education_status = 'College'
      AND d.d_year = 2001
      AND i.inv_quantity_on_hand > 100
      AND p.p_discount_active = 'Y'
      AND wp.wp_char_count BETWEEN 2000 AND 4000
      AND wr.wr_fee > 30
    GROUP BY w.w_warehouse_name, d.d_year
)
SELECT
    warehouse_name,
    d_year,
    total_return_amt,
    avg_fee,
    distinct_orders,
    min_return,
    max_return,
    return_level,
    ROW_NUMBER() OVER (PARTITION BY warehouse_name ORDER BY total_return_amt DESC) AS rn_warehouse
FROM base
ORDER BY total_return_amt DESC
LIMIT 100
