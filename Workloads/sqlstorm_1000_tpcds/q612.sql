WITH sales_union AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    UNION ALL
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid_inc_tax AS net_paid_inc_tax,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
),
sales_agg AS (
    SELECT
        customer_sk,
        COUNT(*) AS sales_transactions,
        SUM(quantity) AS total_quantity,
        SUM(net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(net_profit) AS total_net_profit,
        MAX(date_sk) AS latest_date_sk,
        AVG(net_profit) AS avg_net_profit_per_tx
    FROM sales_union
    GROUP BY customer_sk
),
returns_union AS (
    SELECT
        sr_customer_sk AS customer_sk,
        sr_return_quantity AS quantity,
        sr_net_loss AS net_loss
    FROM store_returns
    UNION ALL
    SELECT
        cr_returning_customer_sk AS customer_sk,
        cr_return_quantity AS quantity,
        cr_net_loss AS net_loss
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_returning_customer_sk AS customer_sk,
        wr_return_quantity AS quantity,
        wr_net_loss AS net_loss
    FROM web_returns
),
returns_agg AS (
    SELECT
        customer_sk,
        SUM(quantity) AS total_return_quantity,
        SUM(net_loss) AS total_return_loss
    FROM returns_union
    GROUP BY customer_sk
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.total_net_profit, 0) AS total_net_profit,
    COALESCE(s.avg_net_profit_per_tx, 0) AS avg_net_profit_per_tx,
    CASE WHEN r.total_return_quantity IS NULL THEN 0 ELSE r.total_return_quantity END AS total_return_quantity,
    CASE WHEN r.total_return_loss IS NULL THEN 0 ELSE r.total_return_loss END AS total_return_loss,
    d.d_year AS latest_year,
    COALESCE(cd.cd_credit_rating, 'UNKNOWN') AS credit_rating,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM sales_union su
            JOIN item i ON su.item_sk = i.i_item_sk
            WHERE su.customer_sk = c.c_customer_sk
              AND i.i_color = 'Red'
        ) THEN 'RED'
        ELSE 'OTHER'
    END AS bought_color_flag,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY COALESCE(s.total_net_profit, 0) DESC) AS state_rank,
    CASE WHEN r.total_return_quantity > 0 THEN 'YES' ELSE 'NO' END AS has_returns,
    CASE
        WHEN COALESCE(s.total_net_profit, 0) > 10000 THEN CONCAT('HIGH_', UPPER(c.c_first_name))
        ELSE CONCAT('LOW_', LOWER(c.c_last_name))
    END AS profit_segment_name
FROM sales_agg s
LEFT JOIN returns_agg r ON s.customer_sk = r.customer_sk
JOIN customer c ON s.customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN date_dim d ON s.latest_date_sk = d.d_date_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE
    (cd.cd_credit_rating = 'Excellent' OR cd.cd_credit_rating IS NULL)
    AND COALESCE(ca.ca_state, 'UNKNOWN') IN ('CA', 'TX', 'NY')
    AND COALESCE(s.total_net_profit, 0) > 0
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
UNION ALL
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    0 AS total_quantity,
    0 AS total_net_profit,
    0 AS avg_net_profit_per_tx,
    0 AS total_return_quantity,
    0 AS total_return_loss,
    NULL AS latest_year,
    COALESCE(cd.cd_credit_rating, 'UNKNOWN') AS credit_rating,
    'NO_DATA' AS bought_color_flag,
    NULL AS state_rank,
    'NO' AS has_returns,
    'NO_SALES' AS profit_segment_name
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE NOT EXISTS (SELECT 1 FROM sales_agg s WHERE s.customer_sk = c.c_customer_sk)
ORDER BY total_net_profit DESC
LIMIT 100
