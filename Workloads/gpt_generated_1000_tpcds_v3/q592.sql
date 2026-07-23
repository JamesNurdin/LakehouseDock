WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        d_sales_date.d_year,
        d_sales_date.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sales_date
        ON cs.cs_sold_date_sk = d_sales_date.d_date_sk
    JOIN date_dim d_ship_date
        ON cs.cs_ship_date_sk = d_ship_date.d_date_sk
    JOIN time_dim t_sales_time
        ON cs.cs_sold_time_sk = t_sales_time.t_time_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN customer_demographics cd_curr_bill
        ON c_bill.c_current_cdemo_sk = cd_curr_bill.cd_demo_sk
    JOIN customer_demographics cd_curr_ship
        ON c_ship.c_current_cdemo_sk = cd_curr_ship.cd_demo_sk
    WHERE d_sales_date.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-03-31'
    GROUP BY
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        d_sales_date.d_year,
        d_sales_date.d_month_seq
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cp.cp_catalog_page_number,
    cs_agg.d_year,
    cs_agg.d_month_seq,
    cs_agg.total_sales,
    cs_agg.total_profit,
    COALESCE(cr_agg.total_return_amount, 0) AS total_return_amount,
    COALESCE(ws_agg.total_web_sales, 0) AS total_web_sales,
    COALESCE(wr_agg.total_web_return_amount, 0) AS total_web_return_amount,
    (cs_agg.total_sales
        - COALESCE(cr_agg.total_return_amount, 0)
        + COALESCE(ws_agg.total_web_sales, 0)
        - COALESCE(wr_agg.total_web_return_amount, 0)
    ) AS net_revenue
FROM cs_agg
JOIN item i
    ON cs_agg.cs_item_sk = i.i_item_sk
JOIN catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN (
    SELECT
        cr.cr_item_sk,
        cr.cr_catalog_page_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_txn_cnt
    FROM catalog_returns cr
    JOIN date_dim d_cr_return
        ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
    JOIN time_dim t_cr_return
        ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN customer c_cr_refund
        ON cr.cr_refunded_customer_sk = c_cr_refund.c_customer_sk
    JOIN customer_demographics cd_cr_refund
        ON cr.cr_refunded_cdemo_sk = cd_cr_refund.cd_demo_sk
    JOIN catalog_page cp_cr
        ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
    WHERE d_cr_return.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-03-31'
    GROUP BY cr.cr_item_sk, cr.cr_catalog_page_sk
) cr_agg
    ON cr_agg.cr_item_sk = cs_agg.cs_item_sk
    AND cr_agg.cr_catalog_page_sk = cs_agg.cs_catalog_page_sk
LEFT JOIN (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(*) AS web_sales_txn_cnt
    FROM web_sales ws
    JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN time_dim t_ws_sold
        ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    JOIN item i_ws
        ON ws.ws_item_sk = i_ws.i_item_sk
    JOIN customer c_ws_bill
        ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
    JOIN customer_demographics cd_ws_bill
        ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    WHERE d_ws_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-03-31'
    GROUP BY ws.ws_item_sk
) ws_agg
    ON ws_agg.ws_item_sk = cs_agg.cs_item_sk
LEFT JOIN (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        COUNT(*) AS web_return_txn_cnt
    FROM web_returns wr
    JOIN date_dim d_wr_return
        ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
    JOIN time_dim t_wr_return
        ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN customer c_wr_refund
        ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
    JOIN customer_demographics cd_wr_refund
        ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
    JOIN web_sales ws2
        ON wr.wr_order_number = ws2.ws_order_number
    WHERE d_wr_return.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-03-31'
    GROUP BY wr.wr_item_sk
) wr_agg
    ON wr_agg.wr_item_sk = cs_agg.cs_item_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    JOIN date_dim d_cr2
        ON cr2.cr_returned_date_sk = d_cr2.d_date_sk
    WHERE cr2.cr_item_sk = cs_agg.cs_item_sk
      AND d_cr2.d_year = cs_agg.d_year
      AND cr2.cr_return_amount > 0
    GROUP BY cr2.cr_item_sk, d_cr2.d_year
    HAVING SUM(cr2.cr_return_amount) / NULLIF(cs_agg.total_sales, 0) > 0.2
)
ORDER BY net_revenue DESC, cs_agg.d_year, cs_agg.d_month_seq
LIMIT 100
