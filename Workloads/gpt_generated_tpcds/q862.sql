WITH date_range AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq
    FROM date_dim
    WHERE d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
),
store_sales_agg AS (
    SELECT dr.d_year,
           dr.d_month_seq,
           SUM(ss.ss_net_paid)   AS store_sales_total,
           SUM(ss.ss_net_profit) AS store_profit_total
    FROM store_sales ss
    JOIN date_range dr ON ss.ss_sold_date_sk = dr.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    GROUP BY dr.d_year, dr.d_month_seq
),
store_returns_agg AS (
    SELECT dr.d_year,
           dr.d_month_seq,
           SUM(sr.sr_net_loss) AS return_loss_total
    FROM store_returns sr
    JOIN date_range dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    GROUP BY dr.d_year, dr.d_month_seq
),
web_sales_agg AS (
    SELECT dr.d_year,
           dr.d_month_seq,
           SUM(ws.ws_net_paid)   AS web_sales_total,
           SUM(ws.ws_net_profit) AS web_profit_total
    FROM web_sales ws
    JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    GROUP BY dr.d_year, dr.d_month_seq
),
inventory_agg AS (
    SELECT dr.d_year,
           dr.d_month_seq,
           SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory inv
    JOIN date_range dr ON inv.inv_date_sk = dr.d_date_sk
    GROUP BY dr.d_year, dr.d_month_seq
)
SELECT dr.d_year,
       dr.d_month_seq,
       COALESCE(ssa.store_sales_total, 0)   AS store_sales_total,
       COALESCE(ssa.store_profit_total, 0)  AS store_profit_total,
       COALESCE(sra.return_loss_total, 0)   AS return_loss_total,
       COALESCE(ssa.store_profit_total, 0) - COALESCE(sra.return_loss_total, 0) AS net_profit_after_returns,
       COALESCE(wsa.web_sales_total, 0)    AS web_sales_total,
       COALESCE(wsa.web_profit_total, 0)   AS web_profit_total,
       COALESCE(ia.total_inventory_on_hand, 0) AS total_inventory_on_hand
FROM date_range dr
LEFT JOIN store_sales_agg   ssa ON dr.d_year = ssa.d_year AND dr.d_month_seq = ssa.d_month_seq
LEFT JOIN store_returns_agg sra ON dr.d_year = sra.d_year AND dr.d_month_seq = sra.d_month_seq
LEFT JOIN web_sales_agg    wsa ON dr.d_year = wsa.d_year AND dr.d_month_seq = wsa.d_month_seq
LEFT JOIN inventory_agg    ia  ON dr.d_year = ia.d_year AND dr.d_month_seq = ia.d_month_seq
ORDER BY dr.d_year, dr.d_month_seq
