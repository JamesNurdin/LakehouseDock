WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2002
    GROUP BY cc.cc_call_center_id, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        cc.cc_call_center_id,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2002
    GROUP BY cc.cc_call_center_id, d.d_year, d.d_month_seq
)
SELECT
    s.cc_call_center_id,
    s.d_year,
    s.d_month_seq,
    s.total_sales_amount,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    CASE WHEN s.total_sales_amount = 0 THEN 0
         ELSE COALESCE(r.total_return_amount, 0) / s.total_sales_amount END AS return_rate,
    s.total_quantity,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    s.total_net_profit,
    CASE WHEN s.total_quantity = 0 THEN 0
         ELSE s.total_discount / s.total_quantity END AS avg_discount_per_item
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cc_call_center_id = r.cc_call_center_id
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
ORDER BY s.total_sales_amount DESC
LIMIT 100
