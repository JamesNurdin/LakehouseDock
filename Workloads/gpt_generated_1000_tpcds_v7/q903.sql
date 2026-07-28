WITH monthly_returns AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       SUM(cr.cr_net_loss) AS month_net_loss,
       COUNT(*) AS returns_cnt,
       AVG(cr.cr_return_tax) AS avg_return_tax,
       SUM(cr.cr_return_quantity) AS total_qty
   FROM catalog_returns cr
   LEFT JOIN date_dim d
       ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_date >= DATE '2001-01-01'
     AND d.d_date < DATE '2002-01-01'
     AND d.d_holiday = 'Y'
     AND d.d_dom IN (13, 20)
     AND cr.cr_return_tax > 10
     AND cr.cr_returning_customer_sk IN (7633027, 10295061, 1214294)
   GROUP BY d.d_year, d.d_month_seq
)
SELECT
    yr,
    AVG(month_net_loss) AS avg_monthly_net_loss,
    SUM(returns_cnt) AS total_returns,
    AVG(avg_return_tax) AS avg_monthly_return_tax
FROM (
    SELECT
        d_year AS yr,
        month_net_loss,
        returns_cnt,
        avg_return_tax
    FROM monthly_returns
) sub
GROUP BY yr
HAVING AVG(month_net_loss) > 5000
ORDER BY yr
