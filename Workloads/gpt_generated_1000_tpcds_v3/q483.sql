WITH sr_summary AS (
    SELECT
        sr.sr_customer_sk AS cust_sk,
        sr.sr_store_sk AS store_sk,
        d_year.d_year AS return_year,
        d_month.d_moy AS return_month,
        COUNT(*) AS store_return_cnt,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN date_dim d_year ON sr.sr_returned_date_sk = d_year.d_date_sk
    JOIN date_dim d_month ON sr.sr_returned_date_sk = d_month.d_date_sk
    GROUP BY sr.sr_customer_sk, sr.sr_store_sk, d_year.d_year, d_month.d_moy
),
cr_summary AS (
    SELECT
        cr.cr_returning_customer_sk AS cust_sk,
        d_year.d_year AS return_year,
        d_month.d_moy AS return_month,
        COUNT(*) AS catalog_return_cnt,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d_year ON cr.cr_returned_date_sk = d_year.d_date_sk
    JOIN date_dim d_month ON cr.cr_returned_date_sk = d_month.d_date_sk
    GROUP BY cr.cr_returning_customer_sk, d_year.d_year, d_month.d_moy
)
SELECT
    s.s_store_name,
    s.s_city,
    d_store_closed.d_year AS store_closed_year,
    c.c_customer_id,
    d_c_first_ship.d_year AS first_ship_year,
    d_c_first_sales.d_year AS first_sales_year,
    sr.return_year,
    sr.return_month,
    sr.store_return_cnt,
    sr.store_return_amount,
    sr.store_net_loss,
    cr.catalog_return_cnt,
    cr.catalog_return_amount,
    cr.catalog_net_loss
FROM sr_summary sr
JOIN cr_summary cr
    ON sr.cust_sk = cr.cust_sk
   AND sr.return_year = cr.return_year
   AND sr.return_month = cr.return_month
JOIN store s
    ON sr.store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN customer c
    ON sr.cust_sk = c.c_customer_sk
JOIN date_dim d_c_first_ship
    ON c.c_first_shipto_date_sk = d_c_first_ship.d_date_sk
JOIN date_dim d_c_first_sales
    ON c.c_first_sales_date_sk = d_c_first_sales.d_date_sk
ORDER BY sr.return_year DESC, s.s_store_name
LIMIT 100
