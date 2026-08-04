/*
Goal: Analyze web sales net revenue broken down by year, warehouse county, and individual promotion channel codes. The query demonstrates string processing with REGEXP_LIKE, LIKE, concatenation, SPLIT, and TRIM, samples the web_sales table, expands a delimited string into rows with UNNEST, aggregates using GROUP BY CUBE, and adds window functions (LAG and a running SUM) over the cube results.
*/
WITH sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (5) -- sample ~5% of rows
),
joined AS (
    SELECT
        ds.d_year,
        w.w_county,
        p.p_promo_id,
        split(p.p_channel_details, ',') AS channel_array,
        ws.ws_net_paid AS net_paid,
        ws.ws_order_number
    FROM sampled_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ds.d_year BETWEEN 2000 AND 2002
      AND regexp_like(p.p_channel_details, 'email')
      AND p.p_promo_name LIKE 'Spring%'
),
expanded AS (
    SELECT
        d_year,
        w_county,
        trim(channel) AS channel,
        net_paid
    FROM joined
    CROSS JOIN UNNEST(channel_array) AS t (channel)
    WHERE length(trim(channel)) > 0
),
aggregated AS (
    SELECT
        d_year,
        w_county,
        channel,
        SUM(net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM expanded
    GROUP BY CUBE (d_year, w_county, channel)
)
SELECT
    d_year,
    w_county,
    channel,
    total_net_paid,
    sales_cnt,
    LAG(total_net_paid) OVER (PARTITION BY d_year ORDER BY w_county, channel) AS lag_total,
    SUM(total_net_paid) OVER (PARTITION BY d_year ORDER BY w_county, channel ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM aggregated
ORDER BY d_year DESC, w_county, channel
LIMIT 100
