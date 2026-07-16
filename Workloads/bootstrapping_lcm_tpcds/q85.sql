WITH returns_by_brand_quarter AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        i.i_brand,
        i.i_category,
        t.t_shift,
        s.s_market_desc,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        SUM(i.i_wholesale_cost) AS total_wholesale_cost
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2019 AND 2021
      AND i.i_category = 'Electronics'
    GROUP BY d.d_year, d.d_quarter_name, i.i_brand, i.i_category, t.t_shift, s.s_market_desc
)
SELECT
    r.d_year,
    r.d_quarter_name,
    r.i_brand,
    r.i_category,
    r.t_shift,
    r.s_market_desc,
    r.return_cnt,
    r.total_return_amt,
    r.avg_return_qty,
    r.total_wholesale_cost,
    CASE WHEN r.total_wholesale_cost > 0 THEN r.total_return_amt / r.total_wholesale_cost ELSE NULL END AS return_to_wholesale_ratio,
    ROW_NUMBER() OVER (PARTITION BY r.i_brand ORDER BY r.total_return_amt DESC) AS brand_return_rank
FROM returns_by_brand_quarter r
WHERE r.return_cnt > 5
ORDER BY r.total_return_amt DESC
LIMIT 200
