WITH date_filtered AS (
    SELECT
        d_date_sk,
        d_fy_year,
        regexp_extract(d_quarter_name, '(\\d{4})Q(\\d)', 1) AS fy_year_str,
        regexp_extract(d_quarter_name, '(\\d{4})Q(\\d)', 2) AS quarter_num,
        d_quarter_name
    FROM date_dim
    WHERE regexp_like(d_quarter_name, '^19[0-9]{2}Q[1-4]$')
      AND d_quarter_name LIKE '%Q1'
),
returns_agg AS (
    SELECT
        df.fy_year_str,
        df.quarter_num,
        COUNT(sr.sr_ticket_number) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_filtered df ON sr.sr_returned_date_sk = df.d_date_sk
    GROUP BY df.fy_year_str, df.quarter_num
),
sales_agg AS (
    SELECT
        df.fy_year_str,
        df.quarter_num,
        COUNT(ws.ws_order_number) AS sales_cnt,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_inc_tax,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM web_sales ws
    JOIN date_filtered df ON ws.ws_sold_date_sk = df.d_date_sk
    GROUP BY df.fy_year_str, df.quarter_num
)
SELECT
    r.fy_year_str AS fiscal_year,
    r.quarter_num AS quarter,
    r.return_cnt,
    r.total_return_amt,
    r.total_net_loss,
    CASE WHEN r.total_return_amt > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
    s.sales_cnt,
    s.total_sales_inc_tax,
    s.total_tax,
    CONCAT('FY', r.fy_year_str, ' Q', r.quarter_num) AS period_label
FROM returns_agg r
LEFT JOIN sales_agg s
    ON r.fy_year_str = s.fy_year_str
   AND r.quarter_num = s.quarter_num
ORDER BY fiscal_year, quarter
LIMIT 100
