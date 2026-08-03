WITH
sales_base AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        d.d_year,
        p.p_promo_name,
        cc.cc_name,
        w.w_warehouse_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND p.p_discount_active = 'Y'
      AND cc.cc_employees > 0
      AND w.w_warehouse_sq_ft > 100000
      AND cs.cs_quantity > 0
      AND cs.cs_net_paid > 0
),
returns_base AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        r.r_reason_desc,
        d.d_year,
        ca.ca_state,
        cd.cd_marital_status,
        sr.sr_addr_sk,
        sr.sr_cdemo_sk
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND sr.sr_return_amt > 0
      AND r.r_reason_desc IS NOT NULL
),
web_returns_base AS (
    SELECT
        wr.wr_refunded_customer_sk,
        wr.wr_returned_date_sk,
        wr.wr_return_amt,
        wr.wr_net_loss,
        r.r_reason_desc AS wr_reason_desc,
        d.d_year AS wr_year,
        wp.wp_type,
        wp.wp_web_page_sk
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND wr.wr_return_amt > 0
),
full_returns AS (
    SELECT
        rb.sr_customer_sk,
        rb.sr_returned_date_sk,
        rb.sr_return_amt,
        rb.sr_net_loss,
        rb.r_reason_desc,
        rb.d_year,
        rb.ca_state,
        rb.cd_marital_status,
        rb.sr_addr_sk,
        rb.sr_cdemo_sk,
        wb.wr_refunded_customer_sk,
        wb.wr_returned_date_sk,
        wb.wr_return_amt,
        wb.wr_net_loss,
        wb.wr_reason_desc,
        wb.wr_year,
        wb.wp_type,
        wb.wp_web_page_sk
    FROM returns_base rb
    FULL OUTER JOIN web_returns_base wb
        ON rb.sr_customer_sk = wb.wr_refunded_customer_sk
       AND rb.sr_returned_date_sk = wb.wr_returned_date_sk
),
site_info AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        ws.web_city,
        d.d_year AS open_year
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ws.web_country = 'United States'
)
SELECT
    c.c_customer_id AS customer_id,
    sb.d_year AS year,
    sb.cs_net_paid AS total_amount,
    CASE WHEN sb.cs_net_paid > 5000 THEN 'High' ELSE 'Low' END AS category,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY sb.cs_net_paid DESC) AS state_rank,
    la.avg_state_paid_last3,
    si.web_name AS site_name
FROM sales_base sb
JOIN customer c ON c.c_customer_sk = sb.cs_bill_customer_sk
LEFT JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN site_info si ON si.web_city = ca.ca_city
LEFT JOIN LATERAL (
    SELECT avg(sb2.cs_net_paid) AS avg_state_paid_last3
    FROM sales_base sb2
    WHERE sb2.cs_bill_customer_sk = sb.cs_bill_customer_sk
      AND sb2.d_year BETWEEN sb.d_year - 2 AND sb.d_year
) la ON TRUE
WHERE EXISTS (
    SELECT 1 FROM catalog_sales cs_ex
    WHERE cs_ex.cs_bill_customer_sk = c.c_customer_sk
      AND cs_ex.cs_sold_date_sk = sb.cs_sold_date_sk
)
UNION DISTINCT
SELECT
    c.c_customer_id AS customer_id,
    fr.d_year AS year,
    COALESCE(fr.sr_return_amt, 0) + COALESCE(fr.wr_return_amt, 0) AS total_amount,
    CASE WHEN COALESCE(fr.sr_return_amt, 0) + COALESCE(fr.wr_return_amt, 0) > 5000 THEN 'High' ELSE 'Low' END AS category,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY COALESCE(fr.sr_return_amt, 0) + COALESCE(fr.wr_return_amt, 0) DESC) AS state_rank,
    la.avg_state_paid_last3,
    si.web_name AS site_name
FROM full_returns fr
JOIN customer c ON c.c_customer_sk = COALESCE(fr.sr_customer_sk, fr.wr_refunded_customer_sk)
LEFT JOIN customer_address ca ON ca.ca_address_sk = fr.sr_addr_sk
LEFT JOIN site_info si ON si.web_city = ca.ca_city
LEFT JOIN LATERAL (
    SELECT avg(sb2.cs_net_paid) AS avg_state_paid_last3
    FROM sales_base sb2
    WHERE sb2.cs_bill_customer_sk = c.c_customer_sk
      AND sb2.d_year BETWEEN fr.d_year - 2 AND fr.d_year
) la ON TRUE
WHERE EXISTS (
    SELECT 1 FROM catalog_sales cs_ex
    WHERE cs_ex.cs_bill_customer_sk = c.c_customer_sk
      AND cs_ex.cs_sold_date_sk = fr.sr_returned_date_sk
)
ORDER BY total_amount DESC
LIMIT 100
