WITH base AS (
    SELECT
        d.d_year,
        cp.cp_department AS department,
        i.i_item_id,
        i.i_current_price,
        w.w_warehouse_name,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        cr.cr_return_amount,
        cr.cr_net_loss,
        CASE WHEN cr.cr_return_amount > 0 THEN 'Positive' ELSE 'Non-Positive' END AS return_category,
        cr.cr_returned_date_sk
    FROM catalog_returns cr TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND i.i_current_price BETWEEN 10 AND 100
      AND cp.cp_department IN ('Books', 'Electronics')
      AND w.w_warehouse_sq_ft > 50000
      AND ib.ib_lower_bound >= 30000
      AND ca.ca_state = 'CA'
),
base_extra AS (
    SELECT
        d.d_year,
        cp.cp_department AS department,
        i.i_item_id,
        i.i_current_price,
        w.w_warehouse_name,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        cr.cr_return_amount,
        cr.cr_net_loss,
        CASE WHEN cr.cr_return_amount > 0 THEN 'Positive' ELSE 'Non-Positive' END AS return_category,
        cr.cr_returned_date_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND i.i_current_price > 200
      AND cp.cp_department = 'Furniture'
      AND w.w_warehouse_sq_ft < 20000
      AND ib.ib_lower_bound < 20000
      AND ca.ca_state = 'TX'
),
unioned AS (
    SELECT * FROM base
    UNION DISTINCT
    SELECT * FROM base_extra
)
SELECT
    d_year,
    department,
    COUNT(*) AS total_returns,
    SUM(cr_return_amount) AS total_amount,
    AVG(cr_return_amount) AS avg_amount,
    SUM(CASE WHEN return_category = 'Positive' THEN cr_return_amount ELSE 0 END) AS positive_amount
FROM unioned
WHERE d_year > (
    SELECT MIN(d_year) FROM date_dim WHERE d_year = 1999
)
GROUP BY d_year, department
ORDER BY total_amount DESC
LIMIT 100
