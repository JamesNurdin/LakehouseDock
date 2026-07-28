WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cp.cp_catalog_number,
        cp.cp_department,
        r.r_reason_desc,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        ws.ws_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        p.p_cost,
        c.c_customer_id,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_location_type,
        d_ret.d_year,
        d_ret.d_month_seq,
        t.t_hour,
        s.s_store_name,
        web.web_name
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_ret.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
)
SELECT
    base.s_store_name,
    base.cp_department,
    base.d_year AS return_year,
    COUNT(DISTINCT base.c_customer_id) AS unique_customers,
    SUM(base.cr_return_amount) AS total_return_amount,
    SUM(base.ws_net_paid) AS total_net_paid,
    AVG(base.ws_ext_discount_amt) AS avg_discount_amount,
    MIN(base.cr_return_quantity) AS min_return_qty,
    MAX(base.ws_quantity) AS max_sales_qty,
    (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_promo_name = base.p_promo_name
    ) AS max_promo_cost,
    RANK() OVER (PARTITION BY base.cp_department ORDER BY SUM(base.ws_net_paid) DESC) AS dept_store_rank
FROM base
WHERE
    base.d_year = 2001
    AND base.ca_state = 'CA'
    AND base.ca_zip = '98579'
    AND base.r_reason_desc LIKE '%price%'
    AND base.p_discount_active = 'Y'
    AND base.t_hour BETWEEN 9 AND 17
    AND base.s_store_name = 'Store 1'
GROUP BY
    base.s_store_name,
    base.cp_department,
    base.d_year,
    base.p_promo_name
ORDER BY
    total_net_paid DESC,
    base.s_store_name
LIMIT 100
