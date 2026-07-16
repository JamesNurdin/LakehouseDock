WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cp.cp_department AS department,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_coupon_amt) AS avg_coupon_amt,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        MIN(cs.cs_sold_date_sk) AS first_sold_date_sk,
        MAX(cs.cs_sold_date_sk) AS last_sold_date_sk
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY cs.cs_bill_customer_sk, cp.cp_department, p.p_promo_name
),
returns_detail AS (
    SELECT
        cr.cr_refunded_customer_sk AS cust_sk,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_quantity) AS qty,
        SUM(cr.cr_return_amount) AS amount,
        COUNT(*) AS cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY cr.cr_refunded_customer_sk, r.r_reason_desc
),
returns_ranked AS (
    SELECT
        cust_sk,
        reason_desc,
        qty,
        amount,
        cnt,
        ROW_NUMBER() OVER (PARTITION BY cust_sk ORDER BY cnt DESC) AS rn
    FROM returns_detail
),
returns_agg AS (
    SELECT
        cust_sk,
        SUM(qty) AS total_return_qty,
        SUM(amount) AS total_return_amount,
        SUM(cnt) AS total_return_cnt,
        MAX(CASE WHEN rn = 1 THEN reason_desc END) AS most_common_return_reason
    FROM returns_ranked
    GROUP BY cust_sk
),
web_visits AS (
    SELECT
        wp.wp_customer_sk AS cust_sk,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages_visited,
        COUNT(*) AS total_page_visits
    FROM web_page wp
    GROUP BY wp.wp_customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk AS cust_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.c_birth_country,
    ci.ca_state,
    s.department,
    s.promo_name,
    s.total_net_profit,
    s.total_quantity,
    r.total_return_qty,
    r.total_return_amount,
    CASE WHEN s.total_quantity > 0 THEN r.total_return_qty * 1.0 / s.total_quantity ELSE 0 END AS return_rate,
    s.avg_coupon_amt,
    s.total_discount,
    r.most_common_return_reason,
    w.distinct_pages_visited,
    w.total_page_visits
FROM sales_agg s
LEFT JOIN returns_agg r ON s.cust_sk = r.cust_sk
LEFT JOIN web_visits w ON s.cust_sk = w.cust_sk
JOIN customer_info ci ON s.cust_sk = ci.cust_sk
WHERE s.total_net_profit > 1000
ORDER BY s.total_net_profit DESC
LIMIT 10
