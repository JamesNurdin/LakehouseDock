WITH sales_union AS (
    SELECT ss.ss_customer_sk AS cust_sk,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           d.d_date AS sale_date,
           'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT cs.cs_bill_customer_sk AS cust_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           d.d_date AS sale_date,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT ws.ws_bill_customer_sk AS cust_sk,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           d.d_date AS sale_date,
           'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
sales_agg AS (
    SELECT cust_sk,
           sum(net_paid) AS total_net_paid,
           sum(net_profit) AS total_net_profit,
           max(sale_date) AS last_sale_date,
           count(DISTINCT channel) AS channels_used
    FROM sales_union
    GROUP BY cust_sk
),
returns_union AS (
    SELECT sr.sr_customer_sk AS cust_sk,
           sr.sr_net_loss AS net_loss,
           d.d_date AS return_date,
           'store' AS channel
    FROM store_returns sr
    LEFT JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT cr.cr_refunded_customer_sk AS cust_sk,
           cr.cr_net_loss AS net_loss,
           d.d_date AS return_date,
           'catalog' AS channel
    FROM catalog_returns cr
    LEFT JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT wr.wr_refunded_customer_sk AS cust_sk,
           wr.wr_net_loss AS net_loss,
           d.d_date AS return_date,
           'web' AS channel
    FROM web_returns wr
    LEFT JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
),
returns_agg AS (
    SELECT cust_sk,
           sum(net_loss) AS total_net_loss,
           max(return_date) AS last_return_date,
           count(DISTINCT channel) AS return_channels_used
    FROM returns_union
    GROUP BY cust_sk
),
customer_details AS (
    SELECT c.c_customer_sk,
           c.c_current_cdemo_sk,
           concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
           c.c_preferred_cust_flag,
           c.c_birth_country,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           cd.cd_credit_rating,
           CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END AS is_preferred,
           coalesce(c.c_birth_country, 'UNKNOWN') AS birth_country_norm
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
most_recent_purchase AS (
    SELECT cust_sk,
           max(purchase_date) AS most_recent_purchase_date
    FROM (
        SELECT ss.ss_customer_sk AS cust_sk, d.d_date AS purchase_date
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        UNION ALL
        SELECT cs.cs_bill_customer_sk AS cust_sk, d.d_date AS purchase_date
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        UNION ALL
        SELECT ws.ws_bill_customer_sk AS cust_sk, d.d_date AS purchase_date
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    ) purchases
    GROUP BY cust_sk
),
final AS (
    SELECT cd.c_customer_sk,
           cd.full_name,
           cd.is_preferred,
           cd.birth_country_norm,
           sa.total_net_paid,
           sa.total_net_profit,
           sa.last_sale_date,
           ra.total_net_loss,
           ra.last_return_date,
           COALESCE(sa.total_net_paid - ra.total_net_loss, sa.total_net_paid) AS net_after_returns,
           mrp.most_recent_purchase_date,
           ROW_NUMBER() OVER (PARTITION BY cd.c_current_cdemo_sk ORDER BY sa.total_net_profit DESC NULLS LAST) AS profit_rank_within_demo,
           RANK() OVER (ORDER BY (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) DESC) AS overall_profit_rank,
           CASE 
               WHEN COALESCE(ra.total_net_loss, 0) > 1000 THEN 'HIGH'
               WHEN COALESCE(ra.total_net_loss, 0) > 0 THEN 'MEDIUM'
               ELSE 'LOW'
           END AS return_severity,
           CASE 
               WHEN cd.birth_country_norm = 'United States' THEN 'Domestic'
               ELSE 'International'
           END AS customer_segment,
           concat(cd.full_name, ' (', c.c_customer_id, ')') AS display_name,
           (SELECT count(*) FROM store_sales ss_sub WHERE ss_sub.ss_customer_sk = cd.c_customer_sk AND ss_sub.ss_quantity > 5) AS high_quantity_order_cnt
    FROM customer_details cd
    LEFT JOIN sales_agg sa ON cd.c_customer_sk = sa.cust_sk
    LEFT JOIN returns_agg ra ON cd.c_customer_sk = ra.cust_sk
    LEFT JOIN most_recent_purchase mrp ON cd.c_customer_sk = mrp.cust_sk
    LEFT JOIN customer c ON c.c_customer_sk = cd.c_customer_sk
    WHERE (cd.is_preferred = 1 OR cd.birth_country_norm = 'United States')
      AND (sa.total_net_paid IS NOT NULL OR ra.total_net_loss IS NOT NULL)
)
SELECT *
FROM final
WHERE overall_profit_rank <= 100
ORDER BY overall_profit_rank
