WITH base AS (
    SELECT
        c.c_customer_id,
        c.c_customer_sk,
        c.c_birth_year,
        ca.ca_city,
        ca.ca_address_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cp.cp_department,
        p_cs.p_promo_name AS cs_promo_name,
        p_cs.p_discount_active AS cs_discount_active,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        wsit.web_name,
        wsit.web_tax_percentage,
        p_ws.p_promo_name AS ws_promo_name,
        p_ws.p_discount_active AS ws_discount_active
    FROM
        customer c
        FULL OUTER JOIN customer_address ca
            ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN store_returns sr
            ON sr.sr_customer_sk = c.c_customer_sk
        LEFT JOIN catalog_sales cs
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        LEFT JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN promotion p_cs
            ON cs.cs_promo_sk = p_cs.p_promo_sk
        LEFT JOIN web_sales ws
            ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN promotion p_ws
            ON ws.ws_promo_sk = p_ws.p_promo_sk
        LEFT JOIN web_site wsit
            ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE
        c.c_birth_year BETWEEN 1960 AND 1995
        AND cp.cp_department = 'Electronics'
        AND cs.cs_net_paid > 1000
        AND ws.ws_net_paid > 500
        AND sr.sr_return_amt > 100
        AND p_cs.p_discount_active = 'Y'
        AND wsit.web_tax_percentage > 0.05
)
SELECT
    base.c_customer_id,
    base.ca_city,
    base.cs_order_number,
    base.ws_order_number AS ws_order_num,
    base.cs_promo_name,
    base.ws_promo_name,
    base.web_name,
    base.sr_return_amt,
    metric.metric_type,
    metric.metric_val,
    ROW_NUMBER() OVER (PARTITION BY base.c_customer_id ORDER BY metric.metric_val DESC) AS rn_by_customer,
    RANK() OVER (ORDER BY metric.metric_val DESC) AS global_rank
FROM
    base
    CROSS JOIN UNNEST(
        map(
            ARRAY['catalog_quantity', 'web_quantity'],
            ARRAY[base.cs_quantity, base.ws_quantity]
        )
    ) AS metric(metric_type, metric_val)
ORDER BY
    global_rank
LIMIT 100
