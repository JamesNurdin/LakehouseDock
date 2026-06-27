WITH sales_agg AS (
    SELECT
        ds.d_year,
        ds.d_month_seq,
        i.i_category,
        sm.sm_type,
        cc.cc_name AS call_center_name,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE ds.d_year = 2001
    GROUP BY ds.d_year, ds.d_month_seq, i.i_category, sm.sm_type, cc.cc_name
),
returns_agg AS (
    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_category,
        sm.sm_type,
        cc.cc_name AS call_center_name,
        SUM(cr.cr_net_loss) AS total_returns_loss,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE dr.d_year = 2001
    GROUP BY dr.d_year, dr.d_month_seq, i.i_category, sm.sm_type, cc.cc_name
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.call_center_name,
    s.i_category,
    s.sm_type,
    s.total_sales,
    COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
    s.total_sales - COALESCE(r.total_returns_loss, 0) AS net_sales_after_returns,
    s.total_quantity,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    s.total_discount
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.i_category = r.i_category
   AND s.sm_type = r.sm_type
   AND s.call_center_name = r.call_center_name
ORDER BY s.d_year, s.d_month_seq, s.call_center_name, s.i_category, s.sm_type
