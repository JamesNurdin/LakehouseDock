WITH per_reason_year AS (
    SELECT
        d.d_year AS year,
        r.r_reason_desc,
        wp.wp_type,
        cd.cd_gender,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(wr.wr_return_amt) AS avg_return_amount
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd
      ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
      AND d.d_current_quarter = 'Y'
      AND r.r_reason_desc LIKE '%gift%'
      AND wp.wp_type = 'content'
      AND cd.cd_gender = 'M'
      AND wr.wr_return_amt > 100
    GROUP BY d.d_year, r.r_reason_desc, wp.wp_type, cd.cd_gender
)
SELECT
    year,
    SUM(total_return_amount) AS year_total_return,
    SUM(total_return_qty) AS year_total_qty,
    AVG(avg_return_amount) AS avg_return_per_group
FROM per_reason_year
GROUP BY year
HAVING SUM(total_return_amount) > 5000
ORDER BY year DESC
