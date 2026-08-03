WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        w.w_county,
        w.w_warehouse_name,
        inv.inv_quantity_on_hand,
        wr.wr_return_amt,
        wr.wr_refunded_cash,
        CASE WHEN wr.wr_return_amt > 100 THEN 'High' ELSE 'Low' END AS return_category,
        cc.cc_state
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    RIGHT JOIN tpcds.warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND w.w_county IN ('Williamson County', 'Walker County')
      AND inv.inv_quantity_on_hand > 0
      AND cc.cc_state = 'CA'
      AND wr.wr_return_amt IS NOT NULL
),
unioned AS (
    SELECT
        b.d_year,
        b.w_county,
        b.return_category,
        SUM(b.wr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS txn_cnt
    FROM base b
    GROUP BY b.d_year, b.w_county, b.return_category

    UNION DISTINCT

    SELECT
        b.d_year,
        b.w_county,
        'All' AS return_category,
        SUM(b.wr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS txn_cnt
    FROM base b
    GROUP BY b.d_year, b.w_county
)
SELECT
    u.d_year,
    u.w_county,
    u.return_category,
    SUM(u.total_refunded_cash) AS total_refunded_cash,
    SUM(u.txn_cnt) AS transaction_count,
    CASE WHEN SUM(u.total_refunded_cash) > (
            SELECT AVG(y.year_total) FROM (
                SELECT SUM(wr.wr_refunded_cash) AS year_total
                FROM tpcds.web_returns wr
                JOIN tpcds.date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
                WHERE d.d_year = 2001
                GROUP BY d.d_year
            ) y
        ) THEN 'Above Avg' ELSE 'Below Avg' END AS performance_flag
FROM unioned u
GROUP BY ROLLUP (u.d_year, u.w_county, u.return_category)
ORDER BY u.d_year ASC NULLS LAST,
         u.w_county ASC NULLS LAST,
         u.return_category ASC NULLS LAST
