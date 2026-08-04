WITH joined AS (
    SELECT
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        i.i_category,
        i.i_wholesale_cost,
        sr.sr_return_quantity,
        sr.sr_fee,
        wr.wr_reversed_charge,
        t_cs.t_hour,
        wp.wp_type,
        d_cs.d_year
    FROM catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    -- store returns linked through the item dimension
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    -- web returns linked through the item dimension
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access   ON wp.wp_access_date_sk   = d_wp_access.d_date_sk
    WHERE d_cs.d_year = 2001
      AND i.i_wholesale_cost > 10
      AND sr.sr_return_quantity >= 10
      AND wr.wr_reversed_charge > 5
      AND t_cs.t_hour BETWEEN 9 AND 17
      AND wp.wp_type = 'HTML'
),
agg AS (
    SELECT
        i_category,
        d_year,
        SUM(cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_level
    FROM joined
    GROUP BY i_category, d_year
),
ranked AS (
    SELECT
        i_category,
        d_year,
        total_profit,
        profit_level,
        RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
    FROM agg
)
SELECT
    r.i_category,
    r.d_year,
    r.total_profit,
    r.profit_level,
    r.profit_rank,
    v.flag
FROM ranked r
CROSS JOIN (VALUES (1), (2)) AS v(flag)
WHERE r.profit_rank <= 10
ORDER BY r.profit_rank, r.i_category
LIMIT 100
