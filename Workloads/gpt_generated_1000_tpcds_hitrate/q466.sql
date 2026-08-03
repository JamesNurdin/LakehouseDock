WITH full_page_return AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_description,
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_warehouse_sk,
        cr.cr_returning_customer_sk
    FROM catalog_page cp
    FULL OUTER JOIN catalog_returns cr
        ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
),
filtered AS (
    SELECT
        fpr.cp_catalog_page_sk,
        fpr.cp_department,
        fpr.cp_catalog_number,
        fpr.cp_description,
        fpr.cr_returned_date_sk,
        fpr.cr_return_quantity,
        fpr.cr_return_amount,
        fpr.cr_warehouse_sk,
        fpr.cr_returning_customer_sk,
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        w.w_warehouse_name,
        w.w_city,
        st.s_store_name,
        ws.web_name,
        la.line_total
    FROM full_page_return fpr
    LEFT JOIN date_dim d
        ON fpr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN customer c
        ON fpr.cr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN warehouse w
        ON fpr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store st
        ON st.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN LATERAL (
        SELECT fpr.cr_return_quantity * fpr.cr_return_amount AS line_total
    ) la ON TRUE
    WHERE
        c.c_preferred_cust_flag = 'Y'
        AND d.d_year BETWEEN 2000 AND 2002
        AND hd.hd_vehicle_count IS NOT NULL
        AND w.w_city IN (SELECT w_city FROM warehouse WHERE w_country = 'United States' LIMIT 5)
        AND ws.web_mkt_id IN (SELECT DISTINCT web_mkt_id FROM web_site WHERE web_mkt_class LIKE '%wide%')
)
SELECT
    DISTINCT f.c_customer_id,
    f.c_preferred_cust_flag,
    f.d_year,
    f.cp_department,
    f.w_warehouse_name,
    SUM(f.line_total) AS total_return_value,
    COUNT(*) AS return_rows,
    t.word AS warehouse_name_word
FROM filtered f
CROSS JOIN UNNEST(split(f.w_warehouse_name, ' ')) AS t(word)
GROUP BY
    f.c_customer_id,
    f.c_preferred_cust_flag,
    f.d_year,
    f.cp_department,
    f.w_warehouse_name,
    t.word
HAVING SUM(f.line_total) > 1000
ORDER BY total_return_value DESC, f.d_year
LIMIT 100
