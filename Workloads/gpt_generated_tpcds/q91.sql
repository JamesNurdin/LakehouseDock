WITH sales_by_cc AS (
    SELECT
        d.d_year,
        d.d_moy,
        cc.cc_name,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_transactions
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, cc.cc_name, i.i_category
),
returns_by_cc AS (
    SELECT
        d.d_year,
        d.d_moy,
        cc.cc_name,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_transactions
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, cc.cc_name, i.i_category
)
SELECT
    s.d_year,
    s.d_moy,
    s.cc_name,
    s.i_category,
    s.total_sales,
    s.total_profit,
    s.sales_transactions,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(r.return_transactions, 0) AS return_transactions,
    s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales,
    s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit
FROM sales_by_cc s
LEFT JOIN returns_by_cc r
  ON s.d_year = r.d_year
 AND s.d_moy = r.d_moy
 AND s.cc_name = r.cc_name
 AND s.i_category = r.i_category
WHERE s.d_year = 2001
ORDER BY s.d_year, s.d_moy, s.cc_name, s.i_category
