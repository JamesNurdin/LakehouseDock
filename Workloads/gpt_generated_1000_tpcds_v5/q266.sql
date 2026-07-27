WITH base AS (
    SELECT
        s.s_store_id,
        s.s_state,
        r.r_reason_desc,
        d.d_year,
        cr.cr_net_loss,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        sr.sr_refunded_cash,
        sr.sr_return_amt,
        cs.cs_net_paid,
        c.c_preferred_cust_flag,
        c.c_customer_id,
        wp.wp_autogen_flag
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_fy_year = 1909
      AND s.s_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND r.r_reason_desc = 'Damaged'
      AND wp.wp_autogen_flag = 'N'
      AND sr.sr_refunded_cash > 100
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_item_sk = cr.cr_item_sk
            AND cs2.cs_quantity > 10
      )
)
SELECT
    b.s_store_id,
    b.s_state,
    b.r_reason_desc,
    b.d_year,
    SUM(b.cr_net_loss)                         AS total_catalog_net_loss,
    SUM(b.sr_refunded_cash)                    AS total_store_refunded_cash,
    AVG(b.cs_net_paid)                         AS avg_sales_net_paid,
    COUNT(DISTINCT b.c_customer_id)            AS distinct_customers,
    MIN(b.cr_return_amount)                    AS min_return_amount,
    MAX(b.sr_return_amt)                       AS max_store_return_amt,
    CASE WHEN SUM(b.cr_return_quantity) > 1000 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category,
    (SELECT AVG(sr3.sr_refunded_cash)
       FROM store_returns sr3
       WHERE sr3.sr_refunded_cash > 0)      AS overall_avg_refunded_cash,
    ROW_NUMBER() OVER (PARTITION BY b.s_state ORDER BY SUM(b.sr_refunded_cash) DESC) AS state_rank
FROM base b
GROUP BY b.s_store_id, b.s_state, b.r_reason_desc, b.d_year
ORDER BY total_store_refunded_cash DESC
LIMIT 100
