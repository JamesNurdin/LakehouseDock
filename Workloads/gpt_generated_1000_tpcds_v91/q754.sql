WITH cs_metrics AS (
    SELECT
        cs.cs_bill_cdemo_sk AS cd_demo_sk,
        cs.cs_sold_date_sk AS date_key,
        t.metric_type,
        t.metric_value
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN UNNEST(
        ARRAY['quantity', 'net_paid_inc_tax'],
        ARRAY[cast(cs.cs_quantity AS double), cast(cs.cs_net_paid_inc_tax AS double)]
    ) AS t (metric_type, metric_value)
    WHERE EXISTS (
        SELECT 1
        FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
          AND cp.cp_department = 'Sports'
    )
      AND cc.cc_state = 'CA'
),
cs_agg AS (
    SELECT
        cd_demo_sk,
        date_key,
        metric_type,
        SUM(metric_value) AS total_metric,
        CAST((SELECT avg(cs_net_paid_inc_tax) FROM catalog_sales) AS double) AS overall_avg
    FROM cs_metrics
    GROUP BY cd_demo_sk, date_key, metric_type
),
sr_metrics AS (
    SELECT
        sr.sr_cdemo_sk AS cd_demo_sk,
        sr.sr_returned_date_sk AS date_key,
        t.metric_type,
        t.metric_value
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN UNNEST(
        ARRAY['return_quantity', 'return_amt'],
        ARRAY[cast(sr.sr_return_quantity AS double), cast(sr.sr_return_amt AS double)]
    ) AS t (metric_type, metric_value)
    WHERE sr.sr_cdemo_sk IN (
        SELECT cd_demo_sk
        FROM customer_demographics
        WHERE cd_gender = 'F' AND cd_dep_count > 0
    )
),
sr_agg AS (
    SELECT
        cd_demo_sk,
        date_key,
        metric_type,
        SUM(metric_value) AS total_metric,
        CAST((SELECT avg(sr_return_amt) FROM store_returns) AS double) AS overall_avg
    FROM sr_metrics
    GROUP BY cd_demo_sk, date_key, metric_type
)
SELECT cd_demo_sk, date_key, metric_type, total_metric, overall_avg
FROM cs_agg
UNION
SELECT cd_demo_sk, date_key, metric_type, total_metric, overall_avg
FROM sr_agg
LIMIT 100
