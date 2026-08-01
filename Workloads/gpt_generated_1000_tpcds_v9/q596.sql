WITH returns_high AS (
    SELECT
        d.d_year AS year,
        cp.cp_department AS department,
        ws.web_state AS state,
        r.r_reason_desc AS reason,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_quantity) AS avg_quantity,
        CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cp.cp_department = 'Electronics'
      AND r.r_reason_id = 'AAAAAAAFAAAAAAA'
      AND ca.ca_state = 'CA'
      AND ws.web_state = 'CA'
      AND cr.cr_return_amount > 200
      AND cr.cr_return_quantity BETWEEN 1 AND 5
      AND ws.web_tax_percentage > 0.05
    GROUP BY d.d_year, cp.cp_department, ws.web_state, r.r_reason_desc
),
returns_low AS (
    SELECT
        d.d_year AS year,
        cp.cp_department AS department,
        ws.web_state AS state,
        r.r_reason_desc AS reason,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_quantity) AS avg_quantity,
        CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cp.cp_department = 'Electronics'
      AND r.r_reason_id = 'AAAAAAAFAAAAAAA'
      AND ca.ca_state = 'CA'
      AND ws.web_state = 'CA'
      AND cr.cr_return_amount <= 200
      AND cr.cr_return_quantity BETWEEN 1 AND 5
      AND ws.web_tax_percentage > 0.05
    GROUP BY d.d_year, cp.cp_department, ws.web_state, r.r_reason_desc
),
combined_returns AS (
    SELECT
        year,
        department,
        state,
        reason,
        total_return_amount,
        total_net_loss,
        return_cnt,
        avg_quantity,
        amount_category
    FROM returns_high
    UNION ALL
    SELECT
        year,
        department,
        state,
        reason,
        total_return_amount,
        total_net_loss,
        return_cnt,
        avg_quantity,
        amount_category
    FROM returns_low
)
SELECT
    cr.year,
    cr.department,
    cr.state,
    cr.reason,
    cr.total_return_amount,
    cr.total_net_loss,
    cr.return_cnt,
    cr.avg_quantity,
    cr.amount_category,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = cr.year
    ) AS avg_year_return_amount,
    ROW_NUMBER() OVER (PARTITION BY cr.department ORDER BY cr.total_return_amount DESC) AS dept_rank
FROM combined_returns cr
ORDER BY cr.total_return_amount DESC, cr.year ASC
LIMIT 100
