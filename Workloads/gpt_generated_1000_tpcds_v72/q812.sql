WITH agg_daily AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        SUM(cr.cr_return_amount) AS total_catalog_return,
        SUM(wr.wr_return_amt) AS total_web_return,
        SUM(cr.cr_return_quantity) AS catalog_qty,
        SUM(wr.wr_return_quantity) AS web_qty,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_orders
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND cr.cr_ship_mode_sk IN (6, 7, 10, 12)
      AND wr.wr_fee > 20
    GROUP BY d.d_year, d.d_month_seq, s.s_store_name
),
agg_store AS (
    SELECT
        s_store_name,
        AVG(total_catalog_return) AS avg_catalog_return,
        AVG(total_web_return) AS avg_web_return,
        SUM(total_catalog_return + total_web_return) AS sum_total_return,
        COUNT(*) AS month_count,
        CASE WHEN AVG(total_catalog_return) > AVG(total_web_return)
             THEN 'CATALOG_HIGH'
             ELSE 'WEB_HIGH'
        END AS higher_source_overall
    FROM agg_daily
    GROUP BY s_store_name
    HAVING SUM(total_catalog_return + total_web_return) > 5000
)
SELECT
    s_store_name,
    avg_catalog_return,
    avg_web_return,
    sum_total_return,
    month_count,
    higher_source_overall,
    sum_total_return / NULLIF(month_count, 0) AS avg_monthly_total_return
FROM agg_store
WHERE avg_catalog_return > 200
  AND avg_web_return > 100
  AND month_count >= 3
  AND higher_source_overall = 'CATALOG_HIGH'
ORDER BY sum_total_return DESC
LIMIT 100
