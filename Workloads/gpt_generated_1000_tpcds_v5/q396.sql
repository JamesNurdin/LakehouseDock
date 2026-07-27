WITH sr_agg AS (
    SELECT
        sr.sr_cdemo_sk,
        d.d_year,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(sr.sr_return_quantity) AS avg_qty
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_week_seq BETWEEN 10 AND 20
      AND sr.sr_return_quantity > 1
      AND sr.sr_net_loss > 0
    GROUP BY sr.sr_cdemo_sk, d.d_year
),

demo_filtered AS (
    SELECT
        cd.cd_gender AS segment,
        a.total_net_loss AS metric_amount,
        a.return_cnt AS metric_count
    FROM sr_agg a
    JOIN customer_demographics cd
        ON a.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
      AND cd.cd_credit_rating = 'Excellent'
      AND cd.cd_dep_count <= 3
),

wp_agg AS (
    SELECT
        wp.wp_type AS segment,
        SUM(wp.wp_char_count) AS metric_amount,
        COUNT(*) AS metric_count
    FROM web_page wp
    JOIN date_dim d2
        ON wp.wp_creation_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2002
      AND wp.wp_type IN ('Home', 'Product')
      AND wp.wp_link_count >= 5
      AND wp.wp_image_count BETWEEN 2 AND 6
    GROUP BY wp.wp_type
),

unioned AS (
    SELECT segment, metric_amount, metric_count FROM demo_filtered
    UNION ALL
    SELECT segment, metric_amount, metric_count FROM wp_agg
)
SELECT
    segment,
    SUM(metric_amount) AS total_amount,
    SUM(metric_count) AS total_records
FROM unioned
GROUP BY segment
HAVING SUM(metric_amount) > 1000
ORDER BY total_amount DESC
LIMIT 100
