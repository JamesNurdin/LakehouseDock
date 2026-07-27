WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        'sales' AS metric_type,
        SUM(ss.ss_ext_sales_price) AS total_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE i.i_class_id = 11
      AND s.s_rec_start_date > DATE '1999-01-01'
    GROUP BY s.s_store_id, s.s_store_name
),
returns_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        'returns' AS metric_type,
        SUM(sr.sr_return_amt) AS total_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE i.i_class_id = 11
      AND s.s_rec_start_date > DATE '1999-01-01'
    GROUP BY s.s_store_id, s.s_store_name
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.metric_type,
    s.total_amount
FROM sales_agg s
UNION ALL
SELECT
    r.s_store_id,
    r.s_store_name,
    r.metric_type,
    r.total_amount
FROM returns_agg r
LIMIT 100
