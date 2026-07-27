WITH joined AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number,
        cr.cr_returning_customer_sk,
        cr.cr_refunded_cash,
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        s.s_state,
        w.web_name,
        w.web_company_name,
        w.web_street_number
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site w
      ON w.web_open_date_sk = d.d_date_sk
)
SELECT
    s_store_name,
    web_name,
    d_year,
    d_month_seq,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_net_loss) AS avg_net_loss,
    COUNT(*) AS returns_cnt,
    MIN(cr_refunded_cash) AS min_refunded_cash,
    MAX(cr_refunded_cash) AS max_refunded_cash
FROM joined
WHERE cr_returning_customer_sk IN (7633027, 3848008, 9746346)
  AND cr_refunded_cash > 500
  AND cr_net_loss BETWEEN 100 AND 3000
  AND web_company_name = 'cally'
  AND s_state = 'CA'
GROUP BY s_store_name, web_name, d_year, d_month_seq
ORDER BY total_return_amount DESC
LIMIT 100
