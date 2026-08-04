WITH base AS (
    SELECT
        wr.wr_returned_date_sk,
        d.d_year,
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_state,
        ca.ca_address_sk AS wr_refunded_addr_sk,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand,
        s.s_store_name,
        s.s_gmt_offset,
        cp.cp_department,
        cp.cp_type,
        ws.web_name,
        wr.wr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date DESC) AS rn
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
    JOIN store s ON d.d_date_sk = s.s_closed_date_sk
    JOIN catalog_page cp ON d.d_date_sk = cp.cp_end_date_sk
    JOIN web_site ws ON d.d_date_sk = ws.web_close_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_state IN ('NY', 'CA', 'TX')
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND inv.inv_quantity_on_hand > 0
      AND s.s_gmt_offset > -5
),
full_join AS (
    SELECT
        d1.d_date_sk,
        s.s_store_name,
        cp.cp_department,
        s.s_gmt_offset,
        cp.cp_type
    FROM store s
    LEFT JOIN date_dim d1 ON s.s_closed_date_sk = d1.d_date_sk
    FULL OUTER JOIN (
        SELECT cp.cp_catalog_page_sk, cp.cp_department, cp.cp_type, d2.d_date_sk
        FROM catalog_page cp
        JOIN date_dim d2 ON cp.cp_end_date_sk = d2.d_date_sk
    ) cp ON d1.d_date_sk = cp.d_date_sk
),
intersect_set AS (
    SELECT c.c_customer_sk FROM customer c WHERE c.c_birth_year BETWEEN 1950 AND 1960
    INTERSECT
    SELECT wr.wr_refunded_customer_sk FROM web_returns wr WHERE wr.wr_return_amt > 100
),
union_set AS (
    SELECT c.c_customer_id FROM customer c WHERE c.c_preferred_cust_flag = 'Y'
    UNION
    SELECT ws.web_site_id FROM web_site ws WHERE ws.web_tax_percentage < 10
),
except_set AS (
    SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_country = 'United States'
    EXCEPT
    SELECT wr.wr_refunded_addr_sk FROM web_returns wr WHERE wr.wr_return_quantity = 0
)
SELECT
    b.d_year,
    b.c_customer_id,
    b.ca_state,
    b.hd_income_band_sk,
    b.inv_quantity_on_hand,
    b.s_store_name,
    b.cp_department,
    b.web_name,
    b.wr_return_amt,
    b.rn,
    fj.s_store_name AS fj_store_name,
    fj.cp_department AS fj_cp_department,
    CASE WHEN i.c_customer_sk IS NOT NULL THEN 1 ELSE 0 END AS in_intersect,
    CASE WHEN u.c_customer_id IS NOT NULL THEN 1 ELSE 0 END AS in_union,
    CASE WHEN e.ca_address_sk IS NOT NULL THEN 1 ELSE 0 END AS in_except
FROM base b
LEFT JOIN full_join fj ON b.wr_returned_date_sk = fj.d_date_sk
LEFT JOIN intersect_set i ON b.c_customer_sk = i.c_customer_sk
LEFT JOIN union_set u ON b.c_customer_id = u.c_customer_id
LEFT JOIN except_set e ON b.wr_refunded_addr_sk = e.ca_address_sk
WHERE b.rn <= 10
ORDER BY b.wr_return_amt DESC
LIMIT 100
