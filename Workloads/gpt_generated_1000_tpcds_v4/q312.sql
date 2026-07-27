WITH city_cte AS (
    SELECT
        cc_call_center_sk,
        cc_city,
        cc_street_name,
        cc_closed_date_sk
    FROM call_center
    WHERE cc_city LIKE '%Hill%'
      AND regexp_like(cc_street_name, '^First|Second')
)
,
store_metrics AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        city_cte.cc_city AS category,
        SUM(ss.ss_net_profit) AS metric,
        COUNT(*) AS txn_cnt,
        'store' AS source
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN city_cte ON city_cte.cc_closed_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_month_seq, city_cte.cc_city
)
,
catalog_return_metrics AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc AS category,
        -SUM(cr.cr_net_loss) AS metric,
        COUNT(*) AS txn_cnt,
        'catalog_return' AS source,
        regexp_extract(r.r_reason_desc, '(Did not like) (.*)', 2) AS reason_detail
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, 'Did not like')
      AND r.r_reason_desc LIKE '%model%'
    GROUP BY d.d_year, d.d_month_seq, r.r_reason_desc, regexp_extract(r.r_reason_desc, '(Did not like) (.*)', 2)
)
SELECT * FROM store_metrics
UNION ALL
SELECT d_year, d_month_seq, category, metric, txn_cnt, source FROM catalog_return_metrics
ORDER BY d_year, d_month_seq, metric DESC
LIMIT 100
