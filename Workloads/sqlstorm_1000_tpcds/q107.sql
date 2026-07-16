WITH
date_bridge AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
),
sales_union AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_call_center_sk AS call_center_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           NULL AS call_center_sk,
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           NULL AS call_center_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           'web' AS channel
    FROM web_sales ws
),
returns_union AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_call_center_sk AS call_center_sk,
           -cr.cr_return_quantity AS quantity,
           -cr.cr_return_amount AS net_paid,
           -cr.cr_net_loss AS net_profit,
           'catalog_return' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_item_sk,
           NULL AS call_center_sk,
           -sr.sr_return_quantity,
           -sr.sr_return_amt,
           -sr.sr_net_loss,
           'store_return' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           NULL AS call_center_sk,
           -wr.wr_return_quantity,
           -wr.wr_return_amt,
           -wr.wr_net_loss,
           'web_return' AS channel
    FROM web_returns wr
),
transactions AS (
    SELECT 
        COALESCE(su.date_sk, ru.date_sk) AS date_sk,
        COALESCE(su.item_sk, ru.item_sk) AS item_sk,
        COALESCE(su.call_center_sk, ru.call_center_sk) AS call_center_sk,
        COALESCE(su.channel, ru.channel) AS channel,
        COALESCE(su.quantity, 0) + COALESCE(ru.quantity, 0) AS quantity,
        COALESCE(su.net_paid, 0) + COALESCE(ru.net_paid, 0) AS net_paid,
        COALESCE(su.net_profit, 0) + COALESCE(ru.net_profit, 0) AS net_profit
    FROM sales_union su
    FULL OUTER JOIN returns_union ru
      ON su.date_sk IS NOT DISTINCT FROM ru.date_sk
     AND su.item_sk IS NOT DISTINCT FROM ru.item_sk
     AND su.call_center_sk IS NOT DISTINCT FROM ru.call_center_sk
),
customers_store AS (
    SELECT DISTINCT ss_customer_sk AS c_customer_sk
    FROM store_sales
),
customers_web AS (
    SELECT DISTINCT ws_bill_customer_sk AS c_customer_sk
    FROM web_sales
),
customers_multi_channel AS (
    SELECT c_customer_sk FROM customers_store
    INTERSECT
    SELECT c_customer_sk FROM customers_web
),
call_center_profit AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        SUM(t.net_profit) AS total_profit,
        COUNT(DISTINCT t.item_sk) AS distinct_items,
        ROW_NUMBER() OVER (ORDER BY SUM(t.net_profit) DESC NULLS LAST) AS profit_rank,
        CASE
            WHEN SUM(t.net_profit) > 1000000 THEN 'HIGH'
            WHEN SUM(t.net_profit) > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM call_center cc
    LEFT JOIN transactions t
        ON cc.cc_call_center_sk = t.call_center_sk
    GROUP BY cc.cc_call_center_sk, cc.cc_name
),
customer_latest_activity AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        (SELECT MAX(d.d_date)
         FROM date_dim d
         WHERE d.d_date_sk IN (
               SELECT ss.ss_sold_date_sk
               FROM store_sales ss
               WHERE ss.ss_customer_sk = c.c_customer_sk
               UNION ALL
               SELECT cs.cs_sold_date_sk
               FROM catalog_sales cs
               WHERE cs.cs_bill_customer_sk = c.c_customer_sk
               UNION ALL
               SELECT ws.ws_sold_date_sk
               FROM web_sales ws
               WHERE ws.ws_bill_customer_sk = c.c_customer_sk
         )
        ) AS latest_purchase_date,
        COALESCE(SUM(cs.cs_net_profit), 0)
        + COALESCE(SUM(ss.ss_net_profit), 0)
        + COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
demographic_customers AS (
    SELECT
        COALESCE(c.c_customer_sk, -1) AS c_customer_sk,
        COALESCE(c.c_email_address, 'no_email@example.com') AS email,
        cd.cd_gender,
        cd.cd_education_status,
        COALESCE(cd.cd_credit_rating, 'UNKNOWN') AS credit_rating
    FROM customer_demographics cd
    RIGHT JOIN customer c
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating IS NULL OR cd.cd_credit_rating = 'UNKNOWN'
),
final_set AS (
    SELECT
        'CALL_CENTER' AS entity_type,
        CAST(cc.cc_call_center_sk AS VARCHAR) AS entity_id,
        cc.cc_name AS entity_name,
        cc.total_profit,
        cc.profit_category,
        NULL AS extra_info
    FROM call_center_profit cc
    WHERE cc.profit_category = 'HIGH'
    UNION ALL
    SELECT
        'CUSTOMER' AS entity_type,
        CAST(c.c_customer_sk AS VARCHAR),
        c.full_name,
        c.total_profit,
        NULL,
        CONCAT(d.cd_gender, '-', d.cd_education_status) AS extra_info
    FROM customer_latest_activity c
    JOIN demographic_customers d
      ON c.c_customer_sk = d.c_customer_sk
    WHERE d.credit_rating = 'UNKNOWN'
      AND c.c_customer_sk IN (SELECT c_customer_sk FROM customers_multi_channel)
)
SELECT
    f.*,
    e.earliest_transaction_date,
    CASE
        WHEN f.entity_type = 'CALL_CENTER' THEN f.total_profit / NULLIF(SUM(f.total_profit) OVER (), 0)
        ELSE NULL
    END AS profit_ratio_to_total,
    ROW_NUMBER() OVER (PARTITION BY f.entity_type ORDER BY COALESCE(f.total_profit, 0) DESC NULLS LAST) AS rank_within_type,
    (SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
     FROM store_sales ss
     WHERE ss.ss_customer_sk = TRY_CAST(f.entity_id AS INTEGER) AND f.entity_type = 'CUSTOMER') AS has_store_sales_flag
FROM final_set f
LEFT JOIN LATERAL (
    SELECT MIN(d.d_date) AS earliest_transaction_date
    FROM transactions t
    JOIN date_dim d ON t.date_sk = d.d_date_sk
    WHERE f.entity_type = 'CALL_CENTER' AND TRY_CAST(f.entity_id AS INTEGER) = t.call_center_sk
) e ON TRUE
WHERE (f.entity_type = 'CALL_CENTER' AND f.total_profit IS NOT NULL)
   OR (f.entity_type = 'CUSTOMER' AND f.extra_info IS NOT NULL)
ORDER BY f.entity_type, rank_within_type
LIMIT 100
