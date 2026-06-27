WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id AS call_center_id,
        d_sales.d_year AS year,
        d_sales.d_month_seq AS month_seq,
        cp.cp_type AS page_type,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS sales_orders
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    GROUP BY cc.cc_call_center_id, d_sales.d_year, d_sales.d_month_seq, cp.cp_type
),
returns_agg AS (
    SELECT
        cc.cc_call_center_id AS call_center_id,
        d_ret.d_year AS year,
        d_ret.d_month_seq AS month_seq,
        cp.cp_type AS page_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    GROUP BY cc.cc_call_center_id, d_ret.d_year, d_ret.d_month_seq, cp.cp_type
)
SELECT
    COALESCE(s.call_center_id, r.call_center_id) AS call_center_id,
    COALESCE(s.year, r.year) AS year,
    COALESCE(s.month_seq, r.month_seq) AS month_seq,
    COALESCE(s.page_type, r.page_type) AS page_type,
    s.total_sales,
    s.total_profit,
    r.total_return_amount,
    r.total_return_loss,
    s.sales_orders,
    r.return_orders,
    (COALESCE(s.total_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
    s.avg_discount
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.call_center_id = r.call_center_id
   AND s.year = r.year
   AND s.month_seq = r.month_seq
   AND s.page_type = r.page_type
ORDER BY call_center_id, year, month_seq, page_type
