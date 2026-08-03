WITH filtered_time AS (
    SELECT
        t_time_sk,
        t_time_id,
        t_am_pm,
        regexp_extract(t_time_id, '(A{3})(A{3})', 1) AS prefix_part,
        CASE WHEN t_am_pm = 'PM' THEN 'Evening' ELSE 'Morning' END AS day_part
    FROM time_dim
    WHERE regexp_like(t_time_id, '^AAAAAAA[AB]')
      AND t_am_pm LIKE 'P%'
),
agg_metrics AS (
    SELECT
        ft.t_time_sk,
        ft.t_time_id,
        ft.t_am_pm,
        ft.prefix_part,
        ft.day_part,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_store_customers,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_web_customers,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(ws.ws_net_profit) AS avg_web_profit,
        SUM(sr.sr_return_tax) AS total_return_tax
    FROM filtered_time ft
    JOIN store_returns sr ON sr.sr_return_time_sk = ft.t_time_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = ft.t_time_sk
    GROUP BY ft.t_time_sk, ft.t_time_id, ft.t_am_pm, ft.prefix_part, ft.day_part
),
day_labels AS (
    SELECT *
    FROM (VALUES 'Morning', 'Evening') AS dl(label)
)
SELECT
    dl.label,
    am.day_part,
    am.distinct_store_customers,
    am.distinct_web_customers,
    am.total_return_amount,
    am.avg_web_profit,
    CASE WHEN am.total_return_tax > 100 THEN 'HighTaxTotal' ELSE 'LowTaxTotal' END AS tax_total_category,
    am.prefix_part
FROM agg_metrics am
CROSS JOIN day_labels dl
WHERE dl.label = am.day_part
ORDER BY am.total_return_amount DESC
LIMIT 100
