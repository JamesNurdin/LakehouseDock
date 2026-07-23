WITH agg AS (
    SELECT
        cc.cc_name,
        cp.cp_catalog_number,
        r.r_reason_desc,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_fee) AS total_return_fee,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        SUM(wr.wr_fee) AS total_web_fee,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        MIN(ss.ss_sales_price) AS min_sales_price,
        MAX(ss.ss_sales_price) AS max_sales_price
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_returned_time_sk = t.t_time_sk AND wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND d.d_moy = 11
      AND t.t_hour BETWEEN 9 AND 17
      AND cc.cc_employees > 100
      AND cp.cp_catalog_number IN (6, 15, 18)
      AND cr.cr_return_amount > 100.00
      AND wr.wr_return_amt > 50.00
      AND ss.ss_net_paid > 0
    GROUP BY
        cc.cc_name,
        cp.cp_catalog_number,
        r.r_reason_desc,
        d.d_year,
        d.d_month_seq,
        t.t_hour
)
SELECT
    agg.cc_name,
    agg.cp_catalog_number,
    agg.r_reason_desc,
    agg.d_year,
    agg.d_month_seq,
    agg.t_hour,
    agg.total_net_paid,
    agg.total_quantity,
    agg.avg_sales_price,
    agg.total_return_amount,
    agg.total_return_fee,
    agg.total_web_return_amount,
    agg.total_web_fee,
    agg.distinct_tickets,
    agg.min_sales_price,
    agg.max_sales_price,
    ROW_NUMBER() OVER (PARTITION BY agg.cc_name ORDER BY agg.total_net_paid DESC) AS rn_by_cc
FROM agg
ORDER BY agg.total_net_paid DESC
LIMIT 100
