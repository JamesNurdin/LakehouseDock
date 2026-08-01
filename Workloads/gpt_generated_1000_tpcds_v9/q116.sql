WITH
sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'Sale' AS txn_type,
        SUM(cs.cs_net_profit) AS amount
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cd.cd_credit_rating = 'High Risk'
      AND cc.cc_company = 1
      AND cp.cp_catalog_number IN (12, 14, 16, 20)
      AND w.w_state = 'CA'
    GROUP BY d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'Return' AS txn_type,
        SUM(cr.cr_net_loss) AS amount
    FROM tpcds.catalog_returns cr
    JOIN tpcds.catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
                               AND cr.cr_item_sk = cs.cs_item_sk
    JOIN tpcds.customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cd.cd_credit_rating = 'High Risk'
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT d_year, d_month_seq, txn_type, amount
FROM sales_agg
UNION ALL
SELECT d_year, d_month_seq, txn_type, amount
FROM returns_agg
ORDER BY d_year DESC, d_month_seq DESC, txn_type
LIMIT 100
