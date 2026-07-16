WITH sales_union AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_store_sk AS channel_sk,
        'store' AS channel,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid_inc_tax AS net_paid_inc_tax
    FROM store_sales ss
    UNION ALL
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_call_center_sk,
        'catalog',
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_net_paid_inc_tax
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk,
        'web',
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax
    FROM web_sales ws
),
returns_union AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_store_sk AS channel_sk,
        'store' AS channel,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS quantity
    FROM store_returns sr
    UNION ALL
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returning_customer_sk,
        cr.cr_call_center_sk,
        'catalog',
        cr.cr_net_loss,
        cr.cr_return_quantity
    FROM catalog_returns cr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returning_customer_sk,
        wr.wr_web_page_sk,
        'web',
        wr.wr_net_loss,
        wr.wr_return_quantity
    FROM web_returns wr
),
customer_latest_sales AS (
    SELECT
        s.customer_sk,
        MAX(d.d_date) AS latest_sale_date
    FROM sales_union s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY s.customer_sk
),
customer_profile AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(c.c_birth_country, 'UNKNOWN') AS birth_country,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential,
        ca.ca_state AS state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_agg AS (
    SELECT
        s.customer_sk,
        s.channel,
        SUM(s.net_profit) AS total_profit,
        SUM(s.net_paid_inc_tax) AS total_paid,
        SUM(s.quantity) AS total_quantity,
        COUNT(*) AS transaction_count
    FROM sales_union s
    GROUP BY s.customer_sk, s.channel
),
returns_agg AS (
    SELECT
        r.customer_sk,
        r.channel,
        SUM(r.net_loss) AS total_loss,
        SUM(r.quantity) AS total_return_qty,
        COUNT(*) AS return_count
    FROM returns_union r
    GROUP BY r.customer_sk, r.channel
),
combined AS (
    SELECT
        cp.customer_sk,
        cp.full_name,
        cp.birth_country,
        cp.gender,
        cp.buy_potential,
        cp.state,
        COALESCE(sa_store.total_profit, 0) AS store_profit,
        COALESCE(sa_store.total_paid, 0) AS store_paid,
        COALESCE(ra_store.total_loss, 0) AS store_loss,
        COALESCE(sa_catalog.total_profit, 0) AS catalog_profit,
        COALESCE(sa_catalog.total_paid, 0) AS catalog_paid,
        COALESCE(ra_catalog.total_loss, 0) AS catalog_loss,
        COALESCE(sa_web.total_profit, 0) AS web_profit,
        COALESCE(sa_web.total_paid, 0) AS web_paid,
        COALESCE(ra_web.total_loss, 0) AS web_loss,
        COALESCE(sa_store.transaction_count, 0) + COALESCE(sa_catalog.transaction_count, 0) + COALESCE(sa_web.transaction_count, 0) AS total_transactions,
        COALESCE(ra_store.return_count, 0) + COALESCE(ra_catalog.return_count, 0) + COALESCE(ra_web.return_count, 0) AS total_returns,
        (COALESCE(sa_store.total_profit, 0) + COALESCE(sa_catalog.total_profit, 0) + COALESCE(sa_web.total_profit, 0)
         - COALESCE(ra_store.total_loss, 0) - COALESCE(ra_catalog.total_loss, 0) - COALESCE(ra_web.total_loss, 0)) AS net_contribution,
        ROW_NUMBER() OVER (
            PARTITION BY cp.state
            ORDER BY (COALESCE(sa_store.total_profit, 0) + COALESCE(sa_catalog.total_profit, 0) + COALESCE(sa_web.total_profit, 0)
                      - COALESCE(ra_store.total_loss, 0) - COALESCE(ra_catalog.total_loss, 0) - COALESCE(ra_web.total_loss, 0)) DESC
        ) AS state_rank
    FROM customer_profile cp
    LEFT JOIN sales_agg sa_store ON cp.customer_sk = sa_store.customer_sk AND sa_store.channel = 'store'
    LEFT JOIN sales_agg sa_catalog ON cp.customer_sk = sa_catalog.customer_sk AND sa_catalog.channel = 'catalog'
    LEFT JOIN sales_agg sa_web ON cp.customer_sk = sa_web.customer_sk AND sa_web.channel = 'web'
    LEFT JOIN returns_agg ra_store ON cp.customer_sk = ra_store.customer_sk AND ra_store.channel = 'store'
    LEFT JOIN returns_agg ra_catalog ON cp.customer_sk = ra_catalog.customer_sk AND ra_catalog.channel = 'catalog'
    LEFT JOIN returns_agg ra_web ON cp.customer_sk = ra_web.customer_sk AND ra_web.channel = 'web'
)
SELECT
    c.customer_sk,
    c.full_name,
    c.state,
    c.birth_country,
    c.gender,
    c.buy_potential,
    c.store_profit,
    c.store_loss,
    c.catalog_profit,
    c.catalog_loss,
    c.web_profit,
    c.web_loss,
    c.total_transactions,
    c.total_returns,
    c.net_contribution,
    CASE
        WHEN c.net_contribution > 10000 THEN 'HIGH'
        WHEN c.net_contribution > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS contribution_category,
    CASE
        WHEN c.state_rank = 1 THEN 'TOP_IN_STATE'
        ELSE NULL
    END AS state_top_flag,
    CONCAT('Customer ', CAST(c.customer_sk AS VARCHAR), ': ', c.full_name) AS description,
    cls.latest_sale_date,
    (SELECT COUNT(*)
     FROM sales_union s2
     WHERE s2.customer_sk = c.customer_sk
       AND s2.channel = 'web'
       AND s2.net_profit > 0) AS web_positive_profit_txns,
    CASE
        WHEN c.state = 'CA' AND c.buy_potential = 'HIGH' THEN 'TARGET'
        ELSE 'NON_TARGET'
    END AS target_flag
FROM combined c
LEFT JOIN customer_latest_sales cls ON c.customer_sk = cls.customer_sk
WHERE c.net_contribution IS NOT NULL
  AND (c.state IS NOT NULL OR c.state = 'CA')
  AND (c.buy_potential = 'HIGH' OR c.buy_potential = 'MEDIUM')
  AND c.state_rank <= 5
ORDER BY c.net_contribution DESC
LIMIT 100
