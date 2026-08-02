WITH returns_by_date AS (
    SELECT 
        cr.cr_returned_date_sk AS date_sk,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cr.cr_returned_date_sk
),

sales_by_date AS (
    SELECT 
        ws.ws_sold_date_sk AS date_sk,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(ws.ws_quantity) AS total_sales_qty
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_sold_date_sk
),

returns_sales_full AS (
    SELECT
        COALESCE(r.date_sk, s.date_sk) AS date_sk,
        r.total_return_loss,
        s.total_sales_profit
    FROM returns_by_date r
    FULL OUTER JOIN sales_by_date s
        ON r.date_sk = s.date_sk
),

coupon_quarter AS (
    SELECT 
        d.d_year,
        d.d_quarter_name,
        SUM(ws.ws_coupon_amt) AS total_coupon_amount,
        COUNT(*) AS num_sales
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_quarter_name = '1904Q2'
      AND ws.ws_coupon_amt > 100
    GROUP BY d.d_year, d.d_quarter_name
)

SELECT 
    d.d_date AS date,
    rs.total_return_loss,
    rs.total_sales_profit,
    CAST(NULL AS decimal(7,2)) AS total_coupon_amount,
    CAST(NULL AS bigint) AS num_sales,
    'Return_Sales' AS record_type
FROM returns_sales_full rs
JOIN date_dim d
    ON rs.date_sk = d.d_date_sk

UNION ALL

SELECT 
    CAST(NULL AS date) AS date,
    CAST(NULL AS decimal(7,2)) AS total_return_loss,
    CAST(NULL AS decimal(7,2)) AS total_sales_profit,
    cq.total_coupon_amount,
    cq.num_sales,
    'Coupon_Quarter' AS record_type
FROM coupon_quarter cq

ORDER BY date ASC NULLS LAST
LIMIT 100
