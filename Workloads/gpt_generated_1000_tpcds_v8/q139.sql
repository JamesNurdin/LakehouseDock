WITH high_cost_and_loss_orders AS (
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_ship_cost > 100
    INTERSECT
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_net_loss > 20
),
joined AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_ship_cost,
        wr.wr_net_loss,
        d.d_quarter_name,
        r.r_reason_desc,
        cp.cp_department
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_quarter_name = '1902Q2'
      AND r.r_reason_desc LIKE '%damaged%'
      AND wr.wr_return_tax > 10
      AND EXISTS (
          SELECT 1
          FROM high_cost_and_loss_orders h
          WHERE h.wr_order_number = wr.wr_order_number
      )
),
agg AS (
    SELECT
        r_reason_desc,
        d_quarter_name,
        cp_department,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(wr_return_amt) AS avg_return_amt
    FROM joined
    GROUP BY GROUPING SETS (
        (r_reason_desc, d_quarter_name, cp_department),
        (r_reason_desc, d_quarter_name),
        (r_reason_desc),
        (d_quarter_name),
        ()
    )
)
SELECT
    COALESCE(r_reason_desc, 'ALL REASONS')        AS reason_desc,
    COALESCE(d_quarter_name, 'ALL QUARTERS')     AS quarter_name,
    COALESCE(cp_department, 'ALL DEPARTMENTS')   AS department,
    total_return_amt,
    total_net_loss,
    return_cnt,
    avg_return_amt,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(cp_department, 'ALL DEPARTMENTS')
        ORDER BY total_return_amt DESC
    )                                            AS dept_rank_by_return
FROM agg
ORDER BY total_return_amt DESC
LIMIT 100
