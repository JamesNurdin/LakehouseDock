WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_color = 'Red'
    GROUP BY s.s_store_id, s.s_state, i.i_category
),
store_returns_agg AS (
    SELECT
        s.s_store_id,
        i.i_category,
        SUM(sr.sr_return_amt_inc_tax) AS total_store_returns
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_store_id, i.i_category
),
web_returns_agg AS (
    SELECT
        s.s_store_id,
        i.i_category,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_returns
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
       AND ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_store_id, i.i_category
)
SELECT
    sa.s_store_id,
    sa.s_state,
    sa.i_category,
    sa.total_sales,
    sa.total_profit,
    COALESCE(sr.total_store_returns, 0) AS total_store_returns,
    COALESCE(wr.total_web_returns, 0) AS total_web_returns,
    (COALESCE(sr.total_store_returns, 0) + COALESCE(wr.total_web_returns, 0)) / NULLIF(sa.total_sales, 0) AS return_rate,
    sa.total_sales - (COALESCE(sr.total_store_returns, 0) + COALESCE(wr.total_web_returns, 0)) AS net_sales_after_returns,
    RANK() OVER (PARTITION BY sa.s_store_id ORDER BY sa.total_sales DESC) AS sales_rank
FROM sales_agg sa
LEFT JOIN store_returns_agg sr
    ON sr.s_store_id = sa.s_store_id
   AND sr.i_category = sa.i_category
LEFT JOIN web_returns_agg wr
    ON wr.s_store_id = sa.s_store_id
   AND wr.i_category = sa.i_category
WHERE sa.total_sales > 10000
ORDER BY net_sales_after_returns DESC
LIMIT 100
