WITH sales_agg AS (
    SELECT
        i.i_item_id,
        cd.cd_gender,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
      AND i.i_units = 'Dozen     '
    GROUP BY i.i_item_id, cd.cd_gender
    HAVING SUM(ss.ss_ext_sales_price) > 1000
),
returns_agg AS (
    SELECT
        i.i_item_id,
        cd.cd_gender,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns,
        SUM(sr.sr_net_loss) AS total_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
      AND i.i_units = 'Dozen     '
    GROUP BY i.i_item_id, cd.cd_gender
    HAVING SUM(sr.sr_return_amt_inc_tax) > 500
)
SELECT
    s.i_item_id,
    s.cd_gender,
    s.total_sales AS amount,
    s.total_profit AS metric,
    'sale' AS record_type
FROM sales_agg s
UNION ALL
SELECT
    r.i_item_id,
    r.cd_gender,
    r.total_returns AS amount,
    r.total_loss AS metric,
    'return' AS record_type
FROM returns_agg r
ORDER BY amount DESC
LIMIT 100
