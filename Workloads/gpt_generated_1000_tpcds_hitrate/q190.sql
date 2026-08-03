WITH joined_data AS (
    SELECT
        s_ss.s_store_name,
        s_ss.s_state,
        d.d_year,
        p_cs.p_promo_name,
        p_cs.p_discount_active,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_bill_customer_sk,
        ss.ss_net_paid,
        sr.sr_return_amt
    FROM date_dim d
    -- catalog sales branch
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    -- store sales branch (shares the same date_dim row)
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN store s_ss
        ON ss.ss_store_sk = s_ss.s_store_sk
    -- store returns branch (also shares the same date_dim row)
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN store s_sr
        ON sr.sr_store_sk = s_sr.s_store_sk
    -- web site branch (open date matches the same date_dim row)
    JOIN web_site web
        ON web.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 1998
        AND ca.ca_state = 'TX'
        AND p_cs.p_response_target = 1
        AND w.w_state = 'CA'
        AND web.web_name = 'WebSite1'
        AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
)
SELECT
    s_store_name,
    s_state,
    d_year,
    p_promo_name,
    CASE WHEN p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(sr_return_amt) AS total_store_returns,
    COUNT(DISTINCT cs_bill_customer_sk) AS distinct_bill_customers,
    AVG(CASE WHEN p_discount_active = 'Y' THEN cs_ext_discount_amt ELSE 0 END) AS avg_discount_when_active
FROM joined_data
GROUP BY
    s_store_name,
    s_state,
    d_year,
    p_promo_name,
    CASE WHEN p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END
ORDER BY total_catalog_sales DESC
LIMIT 100
