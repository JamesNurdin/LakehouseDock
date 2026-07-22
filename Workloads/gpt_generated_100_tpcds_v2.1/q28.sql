WITH filtered_promos AS (
    SELECT p.p_promo_sk
    FROM promotion p
    WHERE regexp_like(p.p_channel_details, '(?i)ideal|effects')
      AND p.p_channel_event = 'N'
),
customer_with_demo AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_purchase_estimate,
        cd.cd_dep_count
    FROM customer c
    JOIN customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_email_address LIKE '%@example.com'
      AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN filtered_promos fp
      ON ws.ws_promo_sk = fp.p_promo_sk
    GROUP BY ws.ws_bill_customer_sk
)
SELECT
    cust.c_customer_id,
    CONCAT(cust.c_first_name, ' ', cust.c_last_name) AS full_name,
    cust.c_email_address,
    cust.cd_purchase_estimate,
    ws_agg.order_cnt,
    ws_agg.total_net_profit,
    COALESCE(sr_stats.total_return_amount, 0) AS total_return_amount,
    CASE
        WHEN regexp_like(cust.c_first_name, '^[A-M]') THEN 'Group A'
        ELSE 'Group B'
    END AS name_group,
    SUBSTRING(cust.c_email_address FROM POSITION('@' IN cust.c_email_address) + 1) AS email_domain
FROM customer_with_demo cust
JOIN web_sales_agg ws_agg
  ON cust.c_customer_sk = ws_agg.customer_sk
LEFT JOIN (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
) sr_stats
  ON cust.c_customer_sk = sr_stats.sr_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_customer_sk = cust.c_customer_sk
      AND sr2.sr_return_amt > 100
)
ORDER BY ws_agg.total_net_profit DESC
LIMIT 100
