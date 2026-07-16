WITH
store_agg AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        d.d_year,
        SUM(ss.ss_net_profit) AS profit,
        SUM(ss.ss_net_paid) AS paid,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
        MAX(d.d_date) AS last_date,
        NULL AS call_center_name
    FROM store_sales ss
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_net_profit IS NOT NULL
    GROUP BY ss.ss_customer_sk, d.d_year
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        d.d_year,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_net_paid) AS paid,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
        MAX(d.d_date) AS last_date,
        NULL AS call_center_name
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_net_profit IS NOT NULL
    GROUP BY ws.ws_bill_customer_sk, d.d_year
),
catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        d.d_year,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_net_paid) AS paid,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        MAX(d.d_date) AS last_date,
        MAX(cc.cc_name) AS call_center_name
    FROM catalog_sales cs
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_net_profit IS NOT NULL
    GROUP BY cs.cs_bill_customer_sk, d.d_year
),
combined AS (
    SELECT
        cust_sk,
        d_year,
        SUM(profit) AS total_profit,
        SUM(paid) AS total_paid,
        SUM(distinct_items) AS total_distinct_items,
        MAX(last_date) AS last_purchase_date,
        MAX(call_center_name) AS latest_call_center
    FROM (
        SELECT * FROM store_agg
        UNION ALL
        SELECT * FROM web_agg
        UNION ALL
        SELECT * FROM catalog_agg
    ) u
    GROUP BY cust_sk, d_year
),
ranked AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d_sub.c_cust_id,
        c.c_preferred_cust_flag,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        comb.d_year,
        comb.total_profit,
        comb.total_paid,
        comb.total_distinct_items,
        comb.last_purchase_date,
        comb.latest_call_center,
        CASE 
            WHEN comb.total_paid = 0 THEN NULL
            ELSE comb.total_profit / comb.total_paid
        END AS profit_margin,
        ROW_NUMBER() OVER (PARTITION BY comb.d_year ORDER BY comb.total_profit DESC) AS profit_rank,
        COUNT(*) OVER (PARTITION BY comb.d_year) AS total_customers_year,
        (
            SELECT COUNT(*)
            FROM store_returns sr
            JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
            WHERE sr.sr_customer_sk = c.c_customer_sk
              AND dr.d_year = comb.d_year
        ) AS store_return_count,
        (
            SELECT MAX(wr.wr_net_loss)
            FROM web_returns wr
            JOIN date_dim dw ON wr.wr_returned_date_sk = dw.d_date_sk
            WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
              AND dw.d_year = comb.d_year
        ) AS latest_web_return_loss
    FROM combined comb
    LEFT JOIN customer c ON comb.cust_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT c_customer_sk, MAX(c_customer_id) AS c_cust_id
        FROM customer
        GROUP BY c_customer_sk
    ) d_sub ON c.c_customer_sk = d_sub.c_customer_sk
    WHERE 
        (c.c_preferred_cust_flag = 'Y' OR cd.cd_credit_rating = 'Good')
        AND comb.total_profit > 0
        AND (ca.ca_state = 'CA' OR ca.ca_state IS NULL)
        AND COALESCE(comb.latest_call_center, '') <> ''
)
SELECT
    profit_rank,
    d_year,
    CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
    CASE
        WHEN profit_margin IS NULL THEN 'N/A'
        ELSE CAST(ROUND(profit_margin * 100, 2) AS VARCHAR) || '%'
    END AS profit_margin_pct,
    total_profit,
    total_paid,
    total_distinct_items,
    last_purchase_date,
    COALESCE(latest_call_center, 'Unknown') AS call_center,
    store_return_count,
    latest_web_return_loss,
    total_customers_year,
    profit_rank * 1.0 / total_customers_year AS rank_percentile
FROM ranked
WHERE profit_rank <= 10
ORDER BY d_year DESC, profit_rank
