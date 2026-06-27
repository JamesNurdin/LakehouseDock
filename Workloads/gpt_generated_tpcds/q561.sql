WITH sales_agg AS (
    SELECT
        p.cp_catalog_page_id,
        d.d_year,
        d.d_moy,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN catalog_page p
        ON cs.cs_catalog_page_sk = p.cp_catalog_page_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim st
        ON cs.cs_sold_time_sk = st.t_time_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND st.t_hour BETWEEN 9 AND 17
    GROUP BY p.cp_catalog_page_id, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        p.cp_catalog_page_id,
        d.d_year,
        d.d_moy,
        SUM(cr.cr_return_amount + cr.cr_return_tax) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN catalog_page p
        ON cr.cr_catalog_page_sk = p.cp_catalog_page_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim rt
        ON cr.cr_returned_time_sk = rt.t_time_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND rt.t_hour BETWEEN 9 AND 17
    GROUP BY p.cp_catalog_page_id, d.d_year, d.d_moy
)
SELECT
    COALESCE(s.cp_catalog_page_id, r.cp_catalog_page_id) AS catalog_page_id,
    COALESCE(s.d_year, r.d_year) AS year,
    COALESCE(s.d_moy, r.d_moy) AS month,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(s.total_sales, 0) - COALESCE(r.total_return_amount, 0) AS net_sales,
    COALESCE(s.total_profit, 0) AS total_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(s.total_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit,
    CASE WHEN COALESCE(s.total_quantity, 0) > 0 THEN COALESCE(s.total_discount, 0) / COALESCE(s.total_quantity, 1) ELSE 0 END AS avg_discount_per_item
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.cp_catalog_page_id = r.cp_catalog_page_id
    AND s.d_year = r.d_year
    AND s.d_moy = r.d_moy
ORDER BY net_sales DESC
LIMIT 100
