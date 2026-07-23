WITH sr_agg AS (
    SELECT
        sr.sr_item_sk,
        dr.d_year,
        dr.d_month_seq,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN time_dim tr ON sr.sr_return_time_sk = tr.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE dr.d_year = 2002
      AND i.i_brand = 'Brand#12'
      AND c.c_salutation = 'Mrs.'
      AND tr.t_hour BETWEEN 9 AND 17
      AND sr.sr_return_quantity >= 2
    GROUP BY sr.sr_item_sk, dr.d_year, dr.d_month_seq
),
ws_agg AS (
    SELECT
        ws.ws_item_sk,
        ds.d_year,
        ds.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_coupon_amt) AS avg_coupon,
        COUNT(*) AS sales_cnt,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM web_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN time_dim ts ON ws.ws_sold_time_sk = ts.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ds.d_year = 2002
      AND i.i_brand = 'Brand#12'
      AND c.c_salutation = 'Mrs.'
      AND ts.t_hour BETWEEN 9 AND 17
      AND ws.ws_coupon_amt > 100.00
      AND w.w_state = 'CA'
    GROUP BY ws.ws_item_sk, ds.d_year, ds.d_month_seq
)
SELECT
    i.i_item_id,
    i.i_product_name,
    ws.d_year,
    ws.d_month_seq,
    ws.total_sales,
    ws.total_profit,
    sr.total_return_amt,
    sr.total_return_loss,
    ws.total_sales - sr.total_return_amt AS net_revenue,
    ws.avg_coupon,
    ws.sales_cnt,
    sr.return_cnt,
    ws.distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY ws.d_year ORDER BY (ws.total_sales - sr.total_return_amt) DESC) AS revenue_rank
FROM ws_agg ws
JOIN sr_agg sr
  ON ws.ws_item_sk = sr.sr_item_sk
 AND ws.d_year = sr.d_year
 AND ws.d_month_seq = sr.d_month_seq
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
ORDER BY ws.d_year, revenue_rank
LIMIT 100
