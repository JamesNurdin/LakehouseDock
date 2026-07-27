WITH cs_agg AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        cs_sold_date_sk AS sold_date_sk,
        SUM(cs_ext_sales_price) AS total_sales_price,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales
    WHERE cs_ext_sales_price > 1000
      AND cs_quantity >= 2
    GROUP BY cs_bill_customer_sk, cs_sold_date_sk
),
sr_agg AS (
    SELECT
        sr_customer_sk AS customer_sk,
        sr_returned_date_sk AS return_date_sk,
        SUM(sr_return_amt_inc_tax) AS total_store_return,
        COUNT(*) AS store_return_cnt
    FROM store_returns
    WHERE sr_return_amt > 0
    GROUP BY sr_customer_sk, sr_returned_date_sk
)
SELECT
    c.c_customer_id,
    d_sales.d_year,
    d_sales.d_month_seq,
    cs_agg.total_sales_price,
    cs_agg.total_profit,
    cs_agg.order_cnt,
    wr_agg.total_return_amount,
    sr_agg.total_store_return,
    ws.ws_net_paid,
    wp.wp_type,
    t.t_hour,
    sr.sr_return_quantity
FROM cs_agg
JOIN customer c
    ON cs_agg.customer_sk = c.c_customer_sk
JOIN date_dim d_sales
    ON cs_agg.sold_date_sk = d_sales.d_date_sk
LEFT JOIN (
    SELECT
        wr_refunded_customer_sk AS customer_sk,
        wr_returned_date_sk AS return_date_sk,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM web_returns
    WHERE wr_return_amt_inc_tax > 0
    GROUP BY wr_refunded_customer_sk, wr_returned_date_sk
) wr_agg
    ON wr_agg.customer_sk = c.c_customer_sk
   AND wr_agg.return_date_sk = d_sales.d_date_sk
LEFT JOIN sr_agg
    ON sr_agg.customer_sk = c.c_customer_sk
   AND sr_agg.return_date_sk = d_sales.d_date_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
   AND sr.sr_returned_date_sk = d_sales.d_date_sk
WHERE c.c_birth_year BETWEEN 1960 AND 1990
  AND d_sales.d_year = 2001
  AND wp.wp_type = 'home'
  AND t.t_hour BETWEEN 9 AND 17
  AND cs_agg.total_sales_price > 5000
  AND EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
          AND wr.wr_net_loss > 500
    )
ORDER BY cs_agg.total_sales_price DESC
LIMIT 100
