WITH sales_returns AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        wr.wr_return_amt,
        sm.sm_ship_mode_id,
        sm.sm_contract,
        sm.sm_code,
        r.r_reason_id,
        r.r_reason_desc,
        wp.wp_web_page_id,
        wp.wp_type,
        t.t_time,
        -- build a small array of numeric measures to be exploded
        ARRAY[cs.cs_ext_ship_cost, cs.cs_net_paid, wr.wr_return_amt] AS measures_arr
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE sm.sm_contract IN ('P7FBIt8yd', 'ldhM8IvpzHgdbBgDfI')
      AND sm.sm_code = 'AIR'
      AND cs.cs_ext_ship_cost > 500
      AND cs.cs_net_paid BETWEEN 500 AND 3000
      AND t.t_time BETWEEN 8 AND 15
      AND wr.wr_return_amt > 100
      AND r.r_reason_id = 'R001'
)
SELECT
    sr.cs_sold_date_sk AS sold_date_key,
    sr.sm_ship_mode_id,
    sr.wp_web_page_id,
    sr.r_reason_desc,
    SUM(sr.cs_ext_ship_cost) AS total_ship_cost,
    AVG(sr.cs_net_paid) AS avg_net_paid,
    COUNT(*) AS transaction_cnt,
    CASE WHEN SUM(sr.cs_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_indicator,
    u.metric_value
FROM sales_returns sr
CROSS JOIN UNNEST(sr.measures_arr) AS u(metric_value)
GROUP BY
    sr.cs_sold_date_sk,
    sr.sm_ship_mode_id,
    sr.wp_web_page_id,
    sr.r_reason_desc,
    u.metric_value
ORDER BY
    total_ship_cost DESC,
    transaction_cnt DESC
LIMIT 100
