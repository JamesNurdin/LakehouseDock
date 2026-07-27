WITH returns_agg AS (
    SELECT
        cp.cp_department,
        d_ret.d_year,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt,
        CASE
            WHEN SUM(wr.wr_fee) > 100 THEN 'High Fee'
            ELSE 'Low Fee'
        END AS fee_category
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN customer cust_ref
        ON wr.wr_refunded_customer_sk = cust_ref.c_customer_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year BETWEEN 2000 AND 2002
      AND wr.wr_fee > 5
      AND wr.wr_return_quantity >= 1
      AND cp.cp_catalog_number IN (5, 9, 12)
      AND cust_ref.c_current_cdemo_sk > 200000
    GROUP BY cp.cp_department, d_ret.d_year
)
SELECT
    cp_department,
    fee_category,
    AVG(total_net_loss) AS avg_total_net_loss,
    SUM(returns_cnt) AS total_returns
FROM returns_agg
GROUP BY cp_department, fee_category
ORDER BY avg_total_net_loss DESC
LIMIT 100
